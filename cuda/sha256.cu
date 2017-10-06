#include <assert.h>
#include <stdbool.h>
#include <stdio.h>
#include "sha256.h"

inline void __cudaCheck(cudaError err, const char* file, int line) {
#ifndef NDEBUG
        if (err != cudaSuccess) {
                fprintf(stderr, "%s(%d): CUDA error: %s\n", __FILE__, __LINE__,
                                cudaGetErrorString(err));
                exit (EXIT_FAILURE);
        }
#endif
}


__constant__ unsigned int C[64] = { 0x428a2f98, 0x71374491, 0xb5c0fbcf,
		0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5, 0xd807aa98,
		0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7,
		0xc19bf174, 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f,
		0x4a7484aa, 0x5cb0a9dc, 0x76f988da, 0x983e5152, 0xa831c66d, 0xb00327c8,
		0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967, 0x27b70a85,
		0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e,
		0x92722c85, 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819,
		0xd6990624, 0xf40e3585, 0x106aa070, 0x19a4c116, 0x1e376c08, 0x2748774c,
		0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3, 0x748f82ee,
		0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7,
		0xc67178f2 };

__constant__ char hex[]="0123456789abcdef";
__constant__ char dni[]="TRWAGMYFPDXBNJZSQVHLCKE";
__device__ void doubleHash(unsigned char* hash, unsigned char * expanded, int lenght) {
#pragma unroll 32
   for (int i=0; i<lenght;i++) {
          expanded[2*i]=hex[ hash[i]/16];
          expanded[2*i+1]=hex[hash[i]%16];
  }
 expanded[2*lenght]='\0';
}

__device__ void printHash(unsigned char* hash, int length) {
	for (int i = 0; i < length; i++) {
		printf("%02x", hash[i]);
	}
	printf("\n");
}


__global__ void sha256cat(unsigned char* datain, unsigned char* strdataout) {
        sha256Context context;
        unsigned char hash[32] ;
        unsigned char strdata[65];
        for (int letra=0; letra <23; letra ++) {
        long int hilo=(blockDim.y*blockIdx.y+threadIdx.y)*blockDim.x*gridDim.x +(blockDim.x*blockIdx.x+threadIdx.x);
        //long int hilo= ( blockIdx.x*blockDim.x + threadIdx.x);
        //int letra = hilo/(100*31*12);
        hilo = hilo /10 ; //para ver si ahora tarda 90 segundos o menos
        int fecha= hilo; //- letra*31*12*100;
        hilo=fecha+letra*(90*31*12);  //solo 90 el year!!
        int year= fecha / (31*12);
        int resto=fecha - year*31*12;
        int mes = resto /31;
        int dia = resto -( mes * 31);
        mes++;
        dia++;
        year+=10;
        sha256Init(&context);
        for (int j=0; j < 20; j++ ) { context.data[j]=datain[j];}
        context.data[5]=dni[letra];
        context.data[8]=hex[year/10];
        context.data[9]=hex[year%10]; 
        context.data[10]=hex[mes/10];
        context.data[11]=hex[mes%10];
        context.data[12]=hex[dia/10];
        context.data[13]=hex[dia%10];
        context.data[19]='\0';
        context.dataLength=19;
        context.bitLength[0]=19*8; //anticipando final
       // printf(".19s\n",&data[0]);        
        //unsigned char tst[]="00000P1996020108034";
        //if (year==96 && mes==2 && dia ==1 &&letra==8 ) {
        //     printf("%s %d\n",data,letra);
        //      printf("%ld %d %d %d \n",hilo,year,mes,dia);
        //    }
        sha256Final(&context, hash);
        for (int j = 0; j < 1715; j++) {
                sha256Init(&context);
                doubleHash(hash,context.data,32);
                context.dataLength=64;
                sha256Transform(&context, context.data);
                //doubleIntAdd(&context.bitLength[0], &context.bitLength[1], 512);
                context.bitLength[0]=512;
                context.dataLength=0;  
                sha256Final(&context, hash);
        }
       doubleHash(hash,strdata,32);
       //printf(".32s\n",strdata);
       //if (year==65)
       //if (year==96 && mes==2 && dia ==1 && letra ==8) {
         //               printf("%d\n",letra);}
                     //printHash(hash,32); }
      //               printf("%ld %d %d %d \n",hilo,year,mes,dia);}
       for (int j=0; j < 64; j++) { strdataout[j+64*hilo]=strdata[j];} 
}
}

__forceinline__ __device__ void sha256Init(sha256Context* context) {
	context->dataLength = 0;
	context->bitLength[0] = 0;
	context->bitLength[1] = 0;
	context->state[0] = 0x6a09e667;
	context->state[1] = 0xbb67ae85;
	context->state[2] = 0x3c6ef372;
	context->state[3] = 0xa54ff53a;
	context->state[4] = 0x510e527f;
	context->state[5] = 0x9b05688c;
	context->state[6] = 0x1f83d9ab;
	context->state[7] = 0x5be0cd19;
}

__forceinline__ __device__ void sha256Final(sha256Context* context, unsigned char* hash) {
	unsigned int length = context->dataLength;
        /*datalenth is zero or 19*/
	context->data[length++] = 0x80;
	for (; length < 56; length++) {
		context->data[length] = 0x00;
	}
	//	memset(context->data, 0, 56);

	// append the total message length in bits and transform.
	//doubleIntAdd(&context->bitLength[0], &context->bitLength[1],
	//		context->dataLength * 8);
#pragma unroll 2
	for (int j = 0; j < 2; j++) {
#pragma unroll 4
		for (int i = 0; i < 4; i++) {
			context->data[63 - i - 4 * j] = context->bitLength[j] >> 8 * i;
		}
	}
	sha256Transform(context, context->data);

	// implementation uses little endian byte ordering and SHA uses big endian, reverse all bytes
#pragma unroll 4
	for (int i = 0; i < 4; i++) {
#pragma unroll 8
		for (int j = 0; j < 8; j++) {
			hash[i + 4 * j] = (context->state[j] >> (24 - i * 8)) & 0x000000ff;
		}
	}
}

__device__ void sha256Transform(sha256Context* context, unsigned char* data) {
	unsigned int shadowRegister[8];
	unsigned int messageSchedule[64];

#pragma unroll 16
	for (int i = 0, j = 0; i < 16; i++, j += 4) {
		messageSchedule[i] = (data[j] << 24) | (data[j + 1] << 16)
				| (data[j + 2] << 8) | (data[j + 3]);
	}
#pragma unroll 48
	for (int i = 16; i < 64; i++) {
		messageSchedule[i] = sigma1(messageSchedule[i - 2])
				+ messageSchedule[i - 7] + sigma0(messageSchedule[i - 15])
				+ messageSchedule[i - 16];
	}

#pragma unroll 8
	for (int i = 0; i < 8; i++) {
		shadowRegister[i] = context->state[i];
	}

#pragma unroll 64
	for (int i = 0; i < 64; i++) {
		unsigned int textRegister1 = shadowRegister[7]
				+ epsilon1(shadowRegister[4])
				+ choice(shadowRegister[4], shadowRegister[5],
						shadowRegister[6]) + C[i] + messageSchedule[i];
		unsigned int textRegister2 = epsilon0(shadowRegister[0])
				+ majority(shadowRegister[0], shadowRegister[1],
						shadowRegister[2]);
#pragma unroll 7
		for (int j = 7; j > 0; j--) {
			shadowRegister[j] = shadowRegister[j - 1];
		}
		shadowRegister[0] = textRegister1 + textRegister2;
		shadowRegister[4] += textRegister1;
	}

#pragma unroll 8
	for (int i = 0; i < 8; i++) {
		context->state[i] += shadowRegister[i];
	}
}


