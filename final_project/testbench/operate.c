#include <defs.h>
#include <user_uart.h>
#include <irq_vex.h>
#include "operate.h"



void __attribute__ ( ( section ( ".mprj" ) ) ) uart_write(int n)
{
    while(((reg_uart_stat>>3) & 1));
    reg_tx_data = n;
}

void __attribute__ ( ( section ( ".mprj" ) ) ) uart_write_char(char c)
{
	if (c == '\n')
		uart_write_char('\r');

    // wait until tx_full = 0
    while(((reg_uart_stat>>3) & 1));
    reg_tx_data = c;
}

void __attribute__ ( ( section ( ".mprj" ) ) ) uart_write_string(const char *s)
{
    while (*s)
        uart_write_char(*(s++));
}


char __attribute__ ( ( section ( ".mprj" ) ) ) uart_read_char()
{
	char num;
    if((((reg_uart_stat>>5) | 0) == 0) && (((reg_uart_stat>>4) | 0) == 0)){
        for(int i = 0; i < 1; i++)
            asm volatile ("nop");

        num = reg_rx_data;
    }

    return num;
}

int __attribute__ ( ( section ( ".mprj" ) ) ) uart_read()
{
    int num;
    if((((reg_uart_stat>>5) | 0) == 0) && (((reg_uart_stat>>4) | 0) == 0)){
        for(int i = 0; i < 1; i++)
            asm volatile ("nop");

        num = reg_rx_data;
    }

    return num;
}


int* __attribute__ ( ( section ( ".mprjram" ) ) ) matmul()
{
	int i;
	int j;
	int k;
	int sum;
	for (i=0; i<SIZE; i++){
		for (j=0; j<SIZE; j++){
			sum = 0;
			for(k = 0;k<SIZE;k++)
				sum += A[(i*SIZE) + k] * B[(k*SIZE) + j];
			result[(i*SIZE) + j] = sum;
		}
	}
	return result;
}




int __attribute__ ( ( section ( ".mprjram" ) ) ) partition(int low,int hi){
	int pivot = QS[hi];
	int i = low-1,j;
	int temp;
	for(j = low;j<hi;j++){
		if(QS[j] < pivot){
			i = i+1;
			temp = QS[i];
			QS[i] = QS[j];
			QS[j] = temp;
		}
	}
	if(QS[hi] < QS[i+1]){
		temp = QS[i+1];
		QS[i+1] = QS[hi];
		QS[hi] = temp;
	}
	return i+1;
}
void __attribute__ ( ( section ( ".mprjram" ) ) ) sort(int low, int hi){
	if(low < hi){
		int p = partition(low, hi);
		sort(low,p-1);
		sort(p+1,hi);
	}
}

int* __attribute__ ( ( section ( ".mprjram" ) ) ) qsort(){
	sort(0,SIZE_QS-1);
	return QS;
}


void __attribute__ ( ( section ( ".mprjram" ) ) ) initfir() {
	// initial your fir
	tap_1 = 0;
	tap_2 = -10;
	tap_3 = -9;
	tap_4 = 23;
	tap_5 = 56;
	tap_6 = 63;
	tap_7 = 56;
	tap_8 = 23;
	tap_9 = -9;
	tap_10= -10;
	tap_11= 0;

	datalength = 64;
	r_start_addr = 0x380010a8;
	w_start_addr = 0x380011f0;

	reg_mprj_datal = 0x00A50000;
	status = 0x00000001;
}

int* __attribute__ ( ( section ( ".mprjram" ) ) ) fir(){
	int s;
	int i = 0;
	initfir();

	// when config fir engine start, the fir engine will 
	// start asking data from user_BRAM through DMA,
	// Once here reveives the done status means end of computing.
	s = status;
	while(!((s >> 1) & 1)) {
		s = status;
	}
	
	reg_mprj_datal = 0xFF5A0000;

	return ans;
}