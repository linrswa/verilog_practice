package i2c_pkg;

    parameter int I2C_ADDR_W = 7;
    parameter int I2C_DATA_W = 8;

    typedef enum logic {
        I2C_WRITE = 1'b0,
        I2C_READ  = 1'b1
    } i2c_rw_e;

    typedef enum logic {
        I2C_ACK  = 1'b0,
        I2C_NACK = 1'b1
    } i2c_ack_e;

endpackage
