#include <stdio.h>
#include <stdlib.h>
#include <i2cUtils.h>
#include <string.h>
#include <time.h>

typedef struct PortData_s {
	float 	Temperature;
	float 	SupplyVoltage;
	float 	RX1Power;
	float	RX2Power;
	float 	RX3Power;
	float 	RX4Power;
	float 	TX1Bias;
	float 	TX2Bias;
	float 	TX3Bias; 
	float 	TX4Bias;
	float 	TX1Power;
	float	TX2Power;
	float 	TX3Power;
	float 	TX4Power;
	float 	TempHighAlarm;
	float 	TempLowAlarm;
	float 	TempHighWarning;
	float 	TempLowWarning;
	float 	VccHighAlarm;
	float 	VccLowAlarm;
	float VccHighWarning;
	float VccLowWarning;
	float RXPowerHighAlarm;
	float RXPowerLowAlarm;
	float RXPowerHighWarning;
	float RXPowerLowWarning;
	float TXBiasHighAlarm;
	float TXBiasLowAlarm;
	float TXBiasHighWarning;
	float TXBiasLowWarning;
	float TXPowerHighAlarm;
	float TXPowerLowAlarm;
	float TXPowerHighWarning;
	float TXPowerLowWarning;
	char VendorName[20];
	char VendorOUI [10];
	char VendorPN[20]; 
	char VendorRev[3];
	char VendorSN[20];
	char DataCode[10];
} PortData_t;

int upper_page00h=2;
int upper_page03h=3;

int read_eeprom(int page, int *value) {
	int err = 0;
	int idx = 0;
	int value1[256];
    time_t mytime;
	if (page == upper_page00h) {
		err = i2cSet(0, 0x50, 0x7f, 0x00);
		if (err != 0) {
			printf("Error reading eeprom %d\n", err);
			return err;
		}
	} else if (page == upper_page03h) {
		err = i2cSet(0, 0x50, 0x7f, 0x03);
		if (err != 0) {
			printf("Error reading eeprom %d\n", err);
			return err;
		}
	}

    mytime = time(NULL);
    printf("%s\n",ctime(&mytime));
	for (idx = 0; idx < 256; idx++) {
		value[idx] = i2cGet(0, 0x50, idx);
	}
	printf("Value from get:");
	for (idx = 0; idx < 256; idx++) {
		printf("%d ", value[idx]);
	}
	printf("\n");
    mytime = time(NULL);
    printf("%s\n",ctime(&mytime));
	err = i2cBulkGet(0, 0x50, 0, 256, value1);
	if (err != 0) {
		printf("Err doing bulk get");
	} else {
		printf("Value from get:");
		for (idx = 0; idx < 256; idx++) {
			printf("%d ", value1[idx]);
		}
		printf("\n");
	}
    mytime = time(NULL);
    printf("%s\n",ctime(&mytime));
	return err;
}

void get_temperature_data(PortData_t *portData, int *value) {
	int msb = value[22];
	int lsb = value[23];
	int shift_value = 0;
	int combine = 0;
	int calculate = 0;

	shift_value = (msb & 0xffff) >> 7;
	combine = ((msb & 0xff) << 8) | (lsb & 0xff);
	if (shift_value == 1) {
		calculate = 0x10000 - combine;
	} else {
		calculate = combine;
	}
	portData->Temperature = (float)calculate/256.0;
}

void get_voltage_data(PortData_t *portData, int *value) {
	int msb = value[26];
	int lsb = value[27];
	int combine = ((msb & 0xff) << 8) | (lsb & 0xff);
	int calculate = combine & 0xffff;

	portData->SupplyVoltage = (float)calculate / 10000.0;
}

float get_power_data(int msb, int lsb) {
	int combine = ((msb & 0xff) << 8) | (lsb & 0xff);
	int calculate = combine & 0xffff;
	return (float)calculate / 10000.0;
}

float get_bias_data(int msb, int lsb) {
	int combine = ((msb & 0xff) << 8) | (lsb & 0xff);
	int calculate = combine & 0xffff;
	return 2.0 * ((float)calculate / 1000.0);
}


void get_rx_power_data(PortData_t *portData, int *value) {
	portData->RX1Power = get_power_data(value[34], value[35]);
	portData->RX2Power = get_power_data(value[36], value[37]);
	portData->RX3Power = get_power_data(value[38], value[39]);
	portData->RX4Power = get_power_data(value[40], value[41]);
}

void get_tx_power_data(PortData_t *portData, int *value) {
	portData->TX1Power = get_power_data(value[50], value[51]);
	portData->TX2Power = get_power_data(value[52], value[53]);
	portData->TX3Power = get_power_data(value[54], value[55]);
	portData->TX4Power = get_power_data(value[56], value[57]);
}

void get_tx_bias_data(PortData_t *portData, int *value) {
	portData->TX1Bias = get_bias_data(value[42], value[43]);
	portData->TX2Bias = get_bias_data(value[44], value[45]);
	portData->TX3Bias = get_bias_data(value[46], value[47]);
	portData->TX4Bias = get_bias_data(value[48], value[49]);
}


void get_data_from_lower_memory(int page, PortData_t *portData) {
	int value[256] = {0};
	int err = 0;

	err = read_eeprom(page, value);
	if (err != 0) {
		return;
	}

	get_temperature_data(portData, value);
	get_voltage_data(portData, value);
	get_rx_power_data(portData, value);
	get_tx_power_data(portData, value);
	get_tx_bias_data(portData, value);
}

void get_vendor_name(PortData_t *portData, int *value) {
	int idx = 0;
	int i = 0;

	for (idx = 148; idx <= 163; idx++) {
		portData->VendorName[i] = value[idx];
		i++;
	}
}

void get_vendor_oui(PortData_t *portData, int *value) {
	snprintf(portData->VendorOUI, 10, "%2X %2X %2X", value[165], value[166], value[167]);
}


void get_vendor_pn(PortData_t *portData, int *value) {
	int idx = 0;
	int i = 0;

	for (idx = 168; idx <= 183; idx++) {
		portData->VendorPN[i] = value[idx];
		i++;
	}
}

void get_vendor_rev(PortData_t *portData, int *value) {
	int idx = 0;
	int i = 0;

	for (idx = 184; idx <= 185; idx++) {
		portData->VendorRev[i] = value[idx];
		i++;
	}
}

void get_vendor_sn(PortData_t *portData, int *value) {
	int idx = 0;
	int i = 0;

	for (idx = 196; idx <= 211; idx++) {
		portData->VendorSN[i] = value[idx];
		i++;
	}
}

void get_vendor_data_code(PortData_t *portData, int *value) {
	int idx = 0;
	int i = 0;

	for (idx = 212; idx <= 219; idx++) {
		portData->DataCode[i] = value[idx];
		i++;
	}
}

void get_data_from_upper_page00h(int page, PortData_t *portData) {
	int value[256] = {0};
	int err = 0;

	err = read_eeprom(page, value);
	if (err != 0) {
		return;
	}

	get_vendor_name(portData, value);
	get_vendor_oui(portData, value);
	get_vendor_pn(portData, value);
	get_vendor_rev(portData, value);
	get_vendor_sn(portData, value);
	get_vendor_data_code(portData, value);
}

void printData(PortData_t *portData) {
	printf("Port Temperature: %f\n", portData->Temperature);
	printf("Port SupplyVoltage: %f\n", portData->SupplyVoltage);
	printf("RX1Power: %f\n", portData->RX1Power);
	printf("RX2Power: %f\n", portData->RX2Power);
	printf("RX3Power: %f\n", portData->RX3Power);
	printf("RX4Power: %f\n", portData->RX4Power);
	printf("TX1Power: %f\n", portData->TX1Power);
	printf("TX2Power: %f\n", portData->TX2Power);
	printf("TX3Power: %f\n", portData->TX3Power);
	printf("TX4Power: %f\n", portData->TX4Power);
	printf("TX1Bias: %f\n", portData->TX1Bias);
	printf("TX2Bias: %f\n", portData->TX2Bias);
	printf("TX3Bias: %f\n", portData->TX3Bias);
	printf("TX4Bias: %f\n", portData->TX4Bias);
	printf("VendorName: %s\n", portData->VendorName);
	printf("VendorOUI: %s\n", portData->VendorOUI);
	printf("VendorPN: %s\n", portData->VendorPN);
	printf("VendorRev: %s\n", portData->VendorRev);
	printf("VendorSN: %s\n", portData->VendorSN);
	printf("DataCode: %s\n", portData->DataCode);
}

int main() {
	int err = 0;
	int port = 0;
	int bit = 0;
	PortData_t *portData = NULL;

	err = i2cSet(0, 0x70, 0x0, 0x00);
	if (err != 0) {
		printf("Error in i2cset: %d\n", err);
		return 0;
	}	
	err = i2cSet(0, 0x71, 0x0, 0x00);
	if (err != 0) {
		printf("Error in i2cset: %d\n", err);
		return 0;
	}

	port = 1;

	if ((port >= 1) && (port <= 8)) {
		bit = (1 << (port - 1)) & 0xff;
		err = i2cSet(0, 0x70, 0x0, bit);
		if (err != 0) {
			printf("Error in i2cset: %d\n", err);
			return 0;
		}	
		err = i2cSet(0, 0x71, 0x0, 0x00);
		if (err != 0) {
			printf("Error in i2cset: %d\n", err);
			return 0;
		}
	} else if ((port >= 9) && (port <= 16)) {
		bit = (1 << (port - 9)) & 0xff;
		err = i2cSet(0, 0x71, 0x0, bit);
		if (err != 0) {
			printf("Error in i2cset: %d\n", err);
			return 0;
		}	
		err = i2cSet(0, 0x70, 0x0, 0x00);
		if (err != 0) {
			printf("Error in i2cset: %d\n", err);
			return 0;
		}
	} else {
		printf("Invalid Port Number");
		return 0;
	}


	portData = malloc(sizeof(PortData_t));
	memset(portData, 0, sizeof(PortData_t));
	get_data_from_lower_memory(2, portData);
	get_data_from_upper_page00h(2, portData);
	//printData(portData);
}
