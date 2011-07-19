/**
 * Writes the kernel and bootloader to
 * a template floppy image file.
 */
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>

int main (int argc, char * argv[]) {
	char boot_buf[512];
	bzero(boot_buf, 512);
	if (argc != 2) {
		fprintf(stderr, "Usage: %s <image.img>\r\n", argv[0]);
		exit(1);
	}
	FILE * bsect = fopen("bin/bsect", "r");
	FILE * sect2 = fopen("bin/sect2", "r");
	FILE * kernel = fopen("bin/kernel", "r");
	FILE * shell = fopen("bin/shell", "r");
	FILE * fp = fopen(argv[1], "r+");
	// bootloader
	fseek(fp, 0, SEEK_SET);
	fread(boot_buf, 1, 510, bsect);
	boot_buf[510] = 0x55;
	boot_buf[511] = 0xaa;
	fwrite(boot_buf, 1, 512, fp);
	// sect2 (kernel loader)
	bzero(boot_buf, 512);
	fread(boot_buf, 1, 512, sect2);
	fseek(fp, 512, SEEK_SET);
	fwrite(boot_buf, 1, 512, fp);
	// kernel (sector 3)
	bzero(boot_buf, 512);
	fread(boot_buf, 1, 512, kernel);
	fseek(fp, 1024, SEEK_SET);
	fwrite(boot_buf, 1, 512, fp);
	// shell (sector 4, in future might be sector 5 as well)
	bzero(boot_buf, 512);
	fread(boot_buf, 1, 512, shell);
	fseek(fp, 1536, SEEK_SET);
	fwrite(boot_buf, 1, 512, fp);
	// close
	fclose(kernel);
	fclose(bsect);
	fclose(sect2);
	fclose(fp);
}
