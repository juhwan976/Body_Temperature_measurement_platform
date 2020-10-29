#include "stdio.h"
#include "app_timer.h"
#include "ble.h"
#include "nrf_soc.h"
#include "nrf_sdh.h"
#include "nrf_sdh_ble.h"
#include "nrf_sdm.h"
#include "ble_advdata.h"
#include "ble_advertising.h"
#include "ble_nus.h"
#include "ble_conn_params.h"
#include "ble_gap.h"
#include "nrf_ble_qwr.h"
#include "nrf_ble_gatt.h"
#include "nrf_log.h"
#include "nrf_log_ctrl.h"
#include "nrf_delay.h"

#include "ble_bas.h"
#include "math.h"
#include "nrf.h"

#include "cssp_gpio.h"

#define DEVICE_NAME                     "BLE_TEST"
#define CONN_CFG_TAG                    1
#define APP_BLE_OBSERVER_PRIO           3
#define FIRST_CONN_PARAMS_UPDATE_DELAY  APP_TIMER_TICKS(5000)
#define NEXT_CONN_PARAMS_UPDATE_DELAY   APP_TIMER_TICKS(30000)
#define MAX_CONN_PARAMS_UPDATE_COUNT    3

#define BATTERY_LEVEL_MEAS_INTERVAL     APP_TIMER_TICKS(2000)
#define MAX_NRF_VOLTAGE                 3.6
#define NOMINAL_BATTERY_VOLTAGE         3
#define MIN_BATTERY_VOLTAGE             2

#define SAADC_RESOLUTION                1024                    // 10bit resolution
#define SAADC_GAIN                      1/6                     // 10bit resolution + 1/6 gain => Max 3.6V

#define MLX90614_REG_AMBIENT_TEMP   0x06    // Ambient Temperature.
#define MLX90614_REG_OBJECT_1_TEMP  0x07    // Temperature of object 1.
#define MLX90614_REG_OBJECT_2_TEMP  0x08    // Temperature of object 2.
#define MLX90614_REG_EMISSIVITY_1   0x24    // Emissivity address
#define MLX90614_REG_EMISSIVITY_2   0x2F    // When use MLX90614xCx, Emissivity address
#define MLX90614_REG_SLEEP          0xFF    // Enter sleep mode.

NRF_BLE_GATT_DEF(gatt);
NRF_BLE_QWR_DEF(qwr);
BLE_ADVERTISING_DEF(advertising);

BLE_NUS_DEF(nus, NRF_SDH_BLE_TOTAL_LINK_COUNT);

BLE_BAS_DEF(m_bas);
APP_TIMER_DEF(m_battery_timer_id);

uint16_t h_connection = BLE_CONN_HANDLE_INVALID;
uint32_t err_code = 0;
uint16_t m_ble_nus_max_data_len = BLE_GATT_ATT_MTU_DEFAULT - 3;
uint16_t rx_buffer[256];
uint16_t tx_buffer[256];

uint16_t saadc_buffer;

bool is_first = true;
float temperature;
uint8_t read_data[3];

char buff[16]; 

void print(const char *message);
void println(const char *message);
void uart_init();
void gpio_init();
void twi_init();
void twi_read();
void saadc_init();
void saadc_sample();

void _BLE_initBLEStacks();
void _BLE_initGAP();
void _BLE_initService();
void _BLE_initAdv();
void _BLE_initConnParams();

void _BLE_init();

void nus_send(const char *message);

static void nrf_qwr_error_handler(uint32_t nrf_error);
static void nus_data_handler(ble_nus_evt_t *p_evt);
static void on_conn_params_evt(ble_conn_params_evt_t *p_evt);
static void conn_params_error_handler(uint32_t nrf_error);
static void gatt_evt_handler(nrf_ble_gatt_t *p_gatt, nrf_ble_gatt_evt_t const *p_evt);
static void on_adv_evt(ble_adv_evt_t ble_adv_evt);
static void ble_evt_handler(ble_evt_t const *p_ble_evt, void *p_context);

static void battery_level_meas_timeout_handler(void *p_context);
static void battery_level_update();
static uint8_t battery_millivolt_to_percent(uint16_t millivolt);
static void timers_init();
static void application_timers_start();

/////////////////////////////////* handlers */////////////////////////////////
void nrf_qwr_error_handler(uint32_t nrf_error) {
    // QWR Module error handler
}

void nus_data_handler(ble_nus_evt_t *p_evt) {
    // Nordic UART Module evt handler
    char ch[200];

    if(p_evt->type == BLE_NUS_EVT_RX_DATA) {
        uint16_t recv_len = p_evt->params.rx_data.length;
        sprintf(ch, "Received Length is %d : ", recv_len);
        print(ch);

        // read data
        for(uint8_t i = 0 ; i < recv_len ; i++) {
            rx_buffer[i] = p_evt->params.rx_data.p_data[i];
            sprintf(ch, "%c", rx_buffer[i]);
            print(ch);
        }
        println("");
    }

    if(p_evt->type == BLE_NUS_EVT_TX_RDY) {
        /* do nothing */
    }
}

void conn_params_error_handler(uint32_t nrf_error) {
    // connection parameter error handler

    /* do nothing */
}

void gatt_evt_handler(nrf_ble_gatt_t *p_gatt, nrf_ble_gatt_evt_t const *p_evt) {
    // GATT evt handler

    if((h_connection == p_evt->conn_handle) && (p_evt->evt_id == NRF_BLE_GATT_EVT_ATT_MTU_UPDATED)) {
        m_ble_nus_max_data_len = p_evt->params.att_mtu_effective - OPCODE_LENGTH - HANDLE_LENGTH;
    }
}

void ble_evt_handler(ble_evt_t const *p_ble_evt, void *p_context) {
    // BLE evt handler

    switch(p_ble_evt->header.evt_id) {
        case BLE_GAP_EVT_CONNECTED:
            // when pairing
            println("BLE connection established");

            // BT LED on
            cssp_gpio_outclr(17);

            // connection handle value update
            h_connection = p_ble_evt->evt.gap_evt.conn_handle;
            err_code = nrf_ble_qwr_conn_handle_assign(&qwr, h_connection);
            break;

        case BLE_GAP_EVT_DISCONNECTED:
            // when unpairing
            println("Disconnected");

            // BT LED off
            cssp_gpio_outset(17);

            // reset handle
            h_connection = BLE_CONN_HANDLE_INVALID;
            break;

        case BLE_GAP_EVT_PHY_UPDATE_REQUEST: {
            ble_gap_phys_t phys;
            phys.rx_phys = BLE_GAP_PHY_AUTO;
            phys.tx_phys = BLE_GAP_PHY_AUTO;
            err_code = sd_ble_gap_phy_update(p_ble_evt->evt.gap_evt.conn_handle, &phys);
            break;
            }
        default:
            break;
    }
}

static void battery_level_meas_timeout_handler(void *p_context) {
    UNUSED_PARAMETER(p_context);
    //println("Battery Level timeout event");

    // Only send the battery level update if we are connected.
    battery_level_update();
}

/////////////////////////////////* functions */////////////////////////////////
void _BLE_init() {
    // Softdevice and BLE stack reset
    println(">>> Enable BLE Stack......");
    _BLE_initBLEStacks();
    println("Complete!");

    // GAP, GATT Sever reset
    println(">>> Initialize GAP, GATT Parameters......");
    _BLE_initGAP();
    println("Complete!");

    // Nordic UART Service, QWR Module reset
    println(">>> Initialize Nordic UART Service & QWR Module......");
    _BLE_initService();
    println("Complete!");

    // Advertising reset
    println(">>> Initialize Advertising data & params......");
    _BLE_initAdv();
    println("Complete!");

    // Connection parameters reset
    println(">>> Initialize Connction parameters.......");
    _BLE_initConnParams();
    println("Complete!");

    // Start Advertising
    println(">>> Try to start advertising......");
    err_code = ble_advertising_start(&advertising, BLE_ADV_MODE_FAST);
    if(!err_code) {
        println("Complete!");
        }
    else {
        println("FAILED!");
        }
}

void _BLE_initBLEStacks() {
    // BLE Stack reset function
    // Softdevice activate
    err_code = nrf_sdh_enable_request();

    // config default BLE Stack
    uint32_t ram_start = 0;
    err_code = nrf_sdh_ble_default_cfg_set(CONN_CFG_TAG, &ram_start);

    // BLE Stack activate
    err_code = nrf_sdh_ble_enable(&ram_start);

    // Config BLE Observer
    NRF_SDH_BLE_OBSERVER(m_ble_observer, APP_BLE_OBSERVER_PRIO, ble_evt_handler, NULL);
}

void _BLE_initGAP() {
    // Reset
    ble_gap_conn_params_t gap_conn_params;  // GAP Connection parameter
    ble_gap_conn_sec_mode_t sec_mode;       // config Security mode
    memset(&gap_conn_params, 0, sizeof(gap_conn_params));

    // Config Security mode(OPEN)
    sec_mode.sm = 1;
    sec_mode.lv = 1;

    // Device name update
    err_code = sd_ble_gap_device_name_set(&sec_mode, (const uint8_t *)DEVICE_NAME, strlen(DEVICE_NAME));

    // Config GAP Connection Parameter
    gap_conn_params.min_conn_interval = 16;   // 20ms
    gap_conn_params.max_conn_interval = 32;   // 40ms
    gap_conn_params.slave_latency     = 0;    // No latency
    gap_conn_params.conn_sup_timeout  = 500;  // 500ms
    
    // Call PPCP Update function
    err_code = sd_ble_gap_ppcp_set(&gap_conn_params);

    // config GATT Normal/Server
    err_code = nrf_ble_gatt_init(&gatt, gatt_evt_handler);

    // MTU Size
    err_code = nrf_ble_gatt_att_mtu_periph_set(&gatt, NRF_SDH_BLE_GATT_MAX_MTU_SIZE);
}

void _BLE_initService() {
    // Nordic UART & QWR Module reset
    // init
    ble_nus_init_t      nus_init;
    nrf_ble_qwr_init_t  qwr_init;
    ble_bas_init_t      bas_init;
    memset(&nus_init, 0, sizeof(nus_init));
    memset(&qwr_init, 0, sizeof(qwr_init));
    memset(&bas_init, 0, sizeof(bas_init));

    // QWR Module error handller
    // QWR Moudle reset
    qwr_init.error_handler = nrf_qwr_error_handler;
    err_code = nrf_ble_qwr_init(&qwr, &qwr_init);

    // Nordic UART Service reset
    // set data handler
    nus_init.data_handler = nus_data_handler;
    err_code = ble_nus_init(&nus, &nus_init);

    // Initialize Battery Service.
    bas_init.bl_rd_sec        = SEC_OPEN;
    bas_init.bl_cccd_wr_sec   = SEC_OPEN;
    bas_init.bl_report_rd_sec = SEC_OPEN;

    bas_init.evt_handler          = NULL;
    bas_init.support_notification = true;
    bas_init.p_report_ref         = NULL;
    bas_init.initial_batt_level   = 100;

    err_code = ble_bas_init(&m_bas, &bas_init);
}

void _BLE_initAdv() {
    // Advertising reset function
    // init
    static ble_advertising_init_t adv_params;
    static ble_uuid_t uuids[1];
    memset(&adv_params, 0, sizeof(adv_params));

    // Advertising Data Packet
    int8_t tx_power = 4;
    adv_params.advdata.name_type = BLE_ADVDATA_FULL_NAME;
    adv_params.advdata.include_appearance = false;
    adv_params.advdata.p_tx_power_level = &tx_power;
    adv_params.advdata.flags = BLE_GAP_ADV_FLAGS_LE_ONLY_LIMITED_DISC_MODE;

    // Scan Response Data
    // UUID
    uuids[0].type = BLE_UUID_TYPE_BLE;
    uuids[0].uuid = BLE_UUID_NUS_SERVICE;
    uuids[1].type = BLE_UUID_TYPE_BLE;
    uuids[1].uuid = BLE_UUID_BATTERY_SERVICE;
    adv_params.srdata.uuids_complete.uuid_cnt = 2;
    adv_params.srdata.uuids_complete.p_uuids = uuids;

    // Advertising parameters
    adv_params.config.ble_adv_fast_enabled = true;
    adv_params.config.ble_adv_fast_interval = 64;
    adv_params.config.ble_adv_fast_timeout = 12000;

    adv_params.evt_handler = on_adv_evt;

    // Reset Advertising
    err_code = ble_advertising_init(&advertising, &adv_params);

    // update config
    ble_advertising_conn_cfg_tag_set(&advertising, CONN_CFG_TAG);
}

void _BLE_initConnParams() {
    // connection parameter
    // init
    ble_conn_params_init_t cp_init;
    memset(&cp_init, 0, sizeof(cp_init));

    // set connection parameter data
    // for Notification
    cp_init.p_conn_params = NULL;
    cp_init.first_conn_params_update_delay = FIRST_CONN_PARAMS_UPDATE_DELAY;
    cp_init.next_conn_params_update_delay = NEXT_CONN_PARAMS_UPDATE_DELAY;
    cp_init.max_conn_params_update_count = MAX_CONN_PARAMS_UPDATE_COUNT;
    cp_init.start_on_notify_cccd_handle = BLE_GATT_HANDLE_INVALID;
    cp_init.disconnect_on_fail = false;
    cp_init.evt_handler = on_conn_params_evt;
    cp_init.error_handler = conn_params_error_handler;

    // reset
    err_code = ble_conn_params_init(&cp_init);
}

void nus_send(const char *message) {
    char ch[40];
    uint16_t tx_len = strlen(message);

    // transmit data
    err_code = ble_nus_data_send(&nus, (uint8_t *)message, &tx_len, h_connection);

    // line change
    /*
    uint8_t crlf[2] = {10, 13};
    tx_len = 2;
    err_code = ble_nus_data_send(&nus, (uint8_t *)crlf, &tx_len, h_connection);
    */
}

void on_conn_params_evt(ble_conn_params_evt_t *p_evt) {
    // connection parameter evt handler
    if(p_evt->evt_type == BLE_CONN_PARAMS_EVT_FAILED) {
        err_code = sd_ble_gap_disconnect(h_connection, BLE_HCI_CONN_INTERVAL_UNACCEPTABLE);
    }
}

void on_adv_evt(ble_adv_evt_t ble_adv_evt) {
    // Advertising evt
    switch(ble_adv_evt) {
        case BLE_ADV_EVT_FAST:
            break;
        case BLE_ADV_EVT_IDLE:
            break;
        default:
            break;
    }
}

void uart_init() {
    NRF_UART0->TASKS_STOPTX = 1;
    NRF_UART0->TASKS_STOPRX = 1;
    NRF_UART0->ENABLE = UART_ENABLE_ENABLE_Disabled;
    NRF_UART0->PSELTXD = 6;
    NRF_UART0->PSELRXD = 8;
    NRF_UART0->CONFIG = (UART_CONFIG_HWFC_Disabled << UART_CONFIG_HWFC_Pos)
                        |(UART_CONFIG_PARITY_Excluded << UART_CONFIG_PARITY_Pos);
    NRF_UART0->BAUDRATE = UART_BAUDRATE_BAUDRATE_Baud115200 << UART_BAUDRATE_BAUDRATE_Pos;
    NRF_UART0->INTENCLR = (UART_INTENCLR_CTS_Clear << UART_INTENCLR_CTS_Pos)
                          |(UART_INTENCLR_ERROR_Clear << UART_INTENCLR_ERROR_Pos)
                          |(UART_INTENCLR_NCTS_Clear << UART_INTENCLR_NCTS_Pos)
                          |(UART_INTENCLR_RXDRDY_Clear << UART_INTENCLR_RXDRDY_Pos)
                          |(UART_INTENCLR_RXTO_Clear << UART_INTENCLR_RXTO_Pos)
                          |(UART_INTENCLR_TXDRDY_Clear << UART_INTENCLR_TXDRDY_Pos);
    NRF_UART0->ENABLE = UART_ENABLE_ENABLE_Enabled;
    NRF_UART0->TASKS_STARTTX = 1;
    NRF_UART0->TASKS_STARTRX = 1;
}

void print(const char *message){
	uint16_t len = strlen(message);
	for(uint8_t i=0;i<len;i++){
		NRF_UART0->TXD = message[i];
		while(!NRF_UART0->EVENTS_TXDRDY){}
		NRF_UART0->EVENTS_TXDRDY = 0;
	}
}

void println(const char *message){
	uint16_t len = strlen(message);
	for(uint8_t i=0;i<len;i++){
		NRF_UART0->TXD = message[i];
		while(!NRF_UART0->EVENTS_TXDRDY){}
		NRF_UART0->EVENTS_TXDRDY = 0;
	}
	NRF_UART0->TXD = 10;
	while(!NRF_UART0->EVENTS_TXDRDY){}
	NRF_UART0->EVENTS_TXDRDY = 0;
	NRF_UART0->TXD = 13;
	while(!NRF_UART0->EVENTS_TXDRDY){}
	NRF_UART0->EVENTS_TXDRDY = 0;
}

void gpio_init() {
    NRF_P0->PIN_CNF[17] = ((GPIO_PIN_CNF_DIR_Output << GPIO_PIN_CNF_DIR_Pos) |
                            (GPIO_PIN_CNF_DRIVE_S0S1 << GPIO_PIN_CNF_DRIVE_Pos) |
                            (GPIO_PIN_CNF_INPUT_Disconnect << GPIO_PIN_CNF_INPUT_Pos) |
                            (GPIO_PIN_CNF_SENSE_Disabled << GPIO_PIN_CNF_SENSE_Pos) |
                            (GPIO_PIN_CNF_PULL_Pullup << GPIO_PIN_CNF_PULL_Pos));

    cssp_gpio_invert(17);
}

void twi_init() {
    NRF_TWI0->ENABLE = TWI_ENABLE_ENABLE_Disabled << TWI_ENABLE_ENABLE_Pos;
    NRF_TWI0->PSELSCL = 27;
    NRF_TWI0->PSELSDA = 26;
    NRF_TWI0->FREQUENCY = TWI_FREQUENCY_FREQUENCY_K100 << TWI_FREQUENCY_FREQUENCY_Pos;
    NRF_TWI0->ADDRESS = 0x5A;   // default address.

    NRF_TWI0->SHORTS = TWI_SHORTS_BB_SUSPEND_Enabled << TWI_SHORTS_BB_SUSPEND_Pos;
    
    NRF_TWI0->INTENSET = TWI_INTENSET_BB_Enabled << TWI_INTENSET_BB_Pos;
    NRF_TWI0->INTENSET = TWI_INTENSET_TXDSENT_Enabled << TWI_INTENSET_TXDSENT_Pos;
    NRF_TWI0->INTENSET = TWI_INTENSET_RXDREADY_Enabled << TWI_INTENSET_RXDREADY_Pos;
    NRF_TWI0->INTENSET = TWI_INTENSET_ERROR_Enabled << TWI_INTENSET_ERROR_Pos;
    NRF_TWI0->INTENSET = TWI_INTENSET_SUSPENDED_Enabled << TWI_INTENSET_SUSPENDED_Pos;
    NRF_TWI0->INTENSET = TWI_INTENSET_STOPPED_Enabled << TWI_INTENSET_STOPPED_Pos;

    NRF_TWI0->ENABLE = TWI_ENABLE_ENABLE_Enabled << TWI_ENABLE_ENABLE_Pos;
}

void twi_read() {
    NRF_TWI0->TXD = MLX90614_REG_OBJECT_1_TEMP;
    NRF_TWI0->TASKS_STARTTX = 1;

    while(1) {
        if(NRF_TWI0->EVENTS_SUSPENDED--)
            break;
    }

    println("1");

    NRF_TWI0->TASKS_RESUME = 1;
    NRF_TWI0->TASKS_STARTRX = 1;

    NRF_TWI0->TASKS_RESUME = 1;
    
    while(1) {
        if(NRF_TWI0->EVENTS_RXDREADY--)
            break;
    }

    println("2");
    
    read_data[0] = NRF_TWI0->RXD;   // LSB
    NRF_TWI0->TASKS_RESUME = 1;

    while(1) {
        if(NRF_TWI0->EVENTS_RXDREADY--)
            break;
    }

    println("3");

    read_data[1] = NRF_TWI0->RXD;   // MSB
    NRF_TWI0->TASKS_RESUME = 1;
    NRF_TWI0->TASKS_STOP = 1;

    while(1) {
        if(NRF_TWI0->EVENTS_RXDREADY--)
            break;
    }

    println("4");

    read_data[2] = NRF_TWI0->RXD;   // CLC
    
    temperature = (((read_data[1] << 8) + (read_data[0])) * 0.02) - 273.15;
}

void saadc_init() {
    if(!NRF_CLOCK->EVENTS_HFCLKSTARTED)
        NRF_CLOCK->TASKS_HFCLKSTART = 1;

    NRF_SAADC->TASKS_STOP = 1;
    NRF_SAADC->CH[0].CONFIG = ((SAADC_CH_CONFIG_MODE_SE) << SAADC_CH_CONFIG_MODE_Pos)|
                              ((SAADC_CH_CONFIG_RESP_Bypass) << SAADC_CH_CONFIG_RESP_Pos) |
                              ((SAADC_CH_CONFIG_RESN_Bypass) << SAADC_CH_CONFIG_RESN_Pos) |
                              ((SAADC_CH_CONFIG_REFSEL_Internal) << SAADC_CH_CONFIG_REFSEL_Pos) |
                              ((SAADC_CH_CONFIG_GAIN_Gain1_6) << SAADC_CH_CONFIG_GAIN_Pos) |
                              ((SAADC_CH_CONFIG_TACQ_3us) << SAADC_CH_CONFIG_TACQ_Pos);

    NRF_SAADC->CH[0].PSELP = SAADC_CH_PSELP_PSELP_VDD << SAADC_CH_PSELP_PSELP_Pos;
    NRF_SAADC->CH[0].PSELN = SAADC_CH_PSELN_PSELN_NC << SAADC_CH_PSELN_PSELN_Pos;

    NRF_SAADC->SAMPLERATE = SAADC_SAMPLERATE_MODE_Task << SAADC_SAMPLERATE_MODE_Pos;
    NRF_SAADC->RESOLUTION = SAADC_RESOLUTION_VAL_10bit << SAADC_RESOLUTION_VAL_Pos;

    NRF_SAADC->RESULT.PTR = (uint32_t)&saadc_buffer;
    NRF_SAADC->RESULT.MAXCNT = 1;

    NRF_SAADC->ENABLE = SAADC_ENABLE_ENABLE_Enabled << SAADC_ENABLE_ENABLE_Pos;

    NRF_SAADC->TASKS_START = 1;
}

void saadc_sample() {
    NRF_SAADC->TASKS_SAMPLE = 1;

    // data save to saadc_buffer
}

static void battery_level_update() {
    ret_code_t err_code;
    uint8_t battery_level;
    
    saadc_sample();

    battery_level =  battery_millivolt_to_percent(saadc_buffer);
//    sprintf(buff, "%d", saadc_buffer);
//    println(buff);

    err_code = ble_bas_battery_level_update(&m_bas, battery_level, BLE_CONN_HANDLE_ALL);
    if ((err_code != NRF_SUCCESS) &&
        (err_code != NRF_ERROR_INVALID_STATE) &&
        (err_code != NRF_ERROR_RESOURCES) &&
        (err_code != BLE_ERROR_GATTS_SYS_ATTR_MISSING)
       )
    {
        APP_ERROR_HANDLER(err_code);
    }
}

static uint8_t battery_millivolt_to_percent(uint16_t millivolt) {
    if(millivolt >= (SAADC_RESOLUTION * NOMINAL_BATTERY_VOLTAGE / MAX_NRF_VOLTAGE))
        return 100;
    else if(millivolt <= (SAADC_RESOLUTION * MIN_BATTERY_VOLTAGE / MAX_NRF_VOLTAGE))
        return 0;
    else
        return (millivolt - (SAADC_RESOLUTION * MIN_BATTERY_VOLTAGE / MAX_NRF_VOLTAGE)) * 100 / ((SAADC_RESOLUTION * NOMINAL_BATTERY_VOLTAGE / MAX_NRF_VOLTAGE) - (SAADC_RESOLUTION * MIN_BATTERY_VOLTAGE / MAX_NRF_VOLTAGE));
}

static void timers_init() {
    ret_code_t  err_code;

    // Initialize timer module.
    err_code = app_timer_init();
    APP_ERROR_CHECK(err_code);

    // Create timers.
    err_code = app_timer_create(&m_battery_timer_id, APP_TIMER_MODE_REPEATED, battery_level_meas_timeout_handler);
    APP_ERROR_CHECK(err_code);
}

static void application_timers_start() {
    ret_code_t err_code;
 
    // Start application timers.
    err_code = app_timer_start(m_battery_timer_id, BATTERY_LEVEL_MEAS_INTERVAL, NULL);
    APP_ERROR_CHECK(err_code);
}

////////* main *////////
void main() {
    uart_init();
    gpio_init();
    saadc_init();
    twi_init();

    timers_init();
    application_timers_start();
    _BLE_init();

    uint16_t count = 0;
    char ch[50];
    
    println("Start BLE UART Example");   

    while(1) {
        twi_read();
        sprintf(ch, "%.2f", (float)temperature);
        nus_send(ch);
        println(ch);
        
        nrf_delay_ms(500);
    }
}