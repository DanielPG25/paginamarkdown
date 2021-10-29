+++ 
draft = true
date = 2021-10-26T13:17:15+02:00
title = "Compilación de un Kernel a medida"
description = "Compilación de un Kernel a medida"
slug = ""
authors = ["Daniel Parrales"]
tags = []
categories = ["Administración de Sistemas Operativos"]
externalLink = ""
series = []
+++

# Compilación de un kernel a medida

En esta práctica vamos a descargar un kernel y vamos a intentar retirarle el mayor número de módulos posibles para reducir al máximo su tamaño, siempre asegurándonos de que siga siendo funcional.

En primer lugar, para tener localizados todos los archivos que descarguemos y generemos, vamos a crear una nueva carpeta:

```
mkdir kernel && cd kernel
```

Ahora vamos a instalar los paquetes que vamos a usar para la compilación (el paquete `qtbase5-dev` lo usaremos más adelante para seleccionar que módulos quitar del kernel de forma más amena):

```
apt install build-essential qtbase5-dev pkg-config
```

También tenemos que averiguar cual es la versión del kernel que estamos usando. Para ello usamos el comando:

```
uname -r

5.10.0-9-amd64
```


Ahora que sabemos nuestra versión del kernel, podemos irnos a [kernel.org](https://mirrors.edge.kernel.org/pub/linux/kernel/) y descargar desde allí la ultima versión disponible (en mi caso la 5.14.13):


`
wget https://mirrors.edge.kernel.org/pub/linux/kernel/v5.x/linux-5.14.13.tar.xz
`

Una vez descargada, debemos descomprimir el archivo:

`
tar -Jxf linux-5.14.13.tar.xz
`

Ahora veamos y comparemos el archivo comprimido con su versión descomprimida:

```
du -sh *

1,2G	linux-5.14.13
116M	linux-5.14.13.tar.xz
```

Como podemos ver, el archivo que descargamos desde la web ocupaba 116MB, mientras que la descompresión ocupa 1.2GB. Nuestra objetivo final será reducir ese tamaño lo máximo posible. Veamos ahora lo que contiene el fichero descomprimido:

```
ls -l

total 876
drwxr-xr-x  25 debian debian   4096 ago 30 00:04 arch
drwxr-xr-x   3 debian debian   4096 ago 30 00:04 block
drwxr-xr-x   2 debian debian   4096 ago 30 00:04 certs
-rw-r--r--   1 debian debian    496 ago 30 00:04 COPYING
-rw-r--r--   1 debian debian 100968 ago 30 00:04 CREDITS
drwxr-xr-x   4 debian debian   4096 ago 30 00:04 crypto
drwxr-xr-x  81 debian debian   4096 ago 30 00:04 Documentation
drwxr-xr-x 139 debian debian   4096 ago 30 00:04 drivers
drwxr-xr-x  80 debian debian   4096 ago 30 00:04 fs
drwxr-xr-x  29 debian debian   4096 ago 30 00:04 include
drwxr-xr-x   2 debian debian   4096 ago 30 00:04 init
drwxr-xr-x   2 debian debian   4096 ago 30 00:04 ipc
-rw-r--r--   1 debian debian   1327 ago 30 00:04 Kbuild
-rw-r--r--   1 debian debian    555 ago 30 00:04 Kconfig
drwxr-xr-x  20 debian debian   4096 ago 30 00:04 kernel
drwxr-xr-x  21 debian debian  12288 ago 30 00:04 lib
drwxr-xr-x   6 debian debian   4096 ago 30 00:04 LICENSES
-rw-r--r--   1 debian debian 612212 ago 30 00:04 MAINTAINERS
-rw-r--r--   1 debian debian  65450 ago 30 00:04 Makefile
drwxr-xr-x   4 debian debian   4096 ago 30 00:04 mm
drwxr-xr-x  71 debian debian   4096 ago 30 00:04 net
-rw-r--r--   1 debian debian    727 ago 30 00:04 README
drwxr-xr-x  34 debian debian   4096 ago 30 00:04 samples
drwxr-xr-x  17 debian debian   4096 ago 30 00:04 scripts
drwxr-xr-x  14 debian debian   4096 ago 30 00:04 security
drwxr-xr-x  27 debian debian   4096 ago 30 00:04 sound
drwxr-xr-x  38 debian debian   4096 ago 30 00:04 tools
drwxr-xr-x   3 debian debian   4096 ago 30 00:04 usr
drwxr-xr-x   4 debian debian   4096 ago 30 00:04 virt
```

Dentro del directorio hay un fichero llamado Makefile, el cual contiene todas las instrucciones que se realizarán al llevar a cabo la compilación del kernel. Para ver todas las opciones disponibles con el comando `make` podemos usar `make help`. De entre todas las opciones, la que más nos interesa ahora es `make oldconfig`, el cual generará un fichero *.config*, el cual contiene la información sobre que módulos serán enlazadados estáticamente y cuales serán enlazados dinámicamente. El comando generará el fichero a partir de nuestra configuración actual del kernel (ubicada en */boot/*). Así pues, ejecutaremos el comando, y como parte del ejercicio, le diremos que no queremos incluir componentes opcionales cada vez que nos lo pregunte (que serán muchas):

`
make oldconfig
`

No pongo la salida del comando, ya que es demasiada larga. Basta con decir que respondí que no a todo lo que pude, y lo que no aceptaba un no, lo dejé como estaba por defecto. Una vez acabado, ya tendremos generado nuestro fichero *.config*:

```
ls -la | egrep .config

-rw-r--r--   1 debian debian     59 ago 30 00:04 .cocciconfig
-rw-r--r--   1 debian debian 241163 oct 19 18:09 .config
-rw-r--r--   1 debian debian    555 ago 30 00:04 Kconfig
```

Veamos ahora cuantos ficheros de *.config* han quedado enlazados dinámicamente (*m*) y cuantos estáticamente (*y*):

```
egrep '=y' .config | wc -l

2188


egrep '=m' .config | wc -l

3721
```

En total hay enlazados 2188 módulos de forma estática y 3721 de forma dinámica, lo que nos da un total de 5909 módulos. Como hay cerca de 6000 módulos, sería una tarea demasiado larga y tediosa el revisarlos todos uno por uno, por lo que haremos uso del comando `make localyesconfig`, que comprobará cuales de los módulos están siendo utilizados en este momento por el sistema y modificará el fichero *.config* en concordancia, descartando los que no estén siendo usados ya no se consideran imprescindibles, y añadiendo los dinámicos al grupo de los estáticos. (No he usado el comando `make localmodconfig` debido a que caba problemas en mi máquina)

```
make localyesconfig

using config: '.config'
glue_helper config not found!!
System keyring enabled but keys "debian/certs/debian-uefi-certs.pem" not found. Resetting keys to default value.
*
* Restart config...
*
*
* PCI GPIO expanders
*
AMD 8111 GPIO driver (GPIO_AMD8111) [N/m/y/?] n
BT8XX GPIO abuser (GPIO_BT8XX) [N/m/y/?] (NEW) n
OKI SEMICONDUCTOR ML7213 IOH GPIO support (GPIO_ML_IOH) [N/m/y/?] n
ACCES PCI-IDIO-16 GPIO support (GPIO_PCI_IDIO_16) [N/m/y/?] n
ACCES PCIe-IDIO-24 GPIO support (GPIO_PCIE_IDIO_24) [N/m/y/?] n
RDC R-321x GPIO support (GPIO_RDC321X) [N/m/y/?] n
*
* PCI sound devices
*
PCI sound devices (SND_PCI) [Y/n/?] y
  Analog Devices AD1889 (SND_AD1889) [N/m/?] n
  Avance Logic ALS300/ALS300+ (SND_ALS300) [N/m/?] n
  Avance Logic ALS4000 (SND_ALS4000) [N/m/?] n
  ALi M5451 PCI Audio Controller (SND_ALI5451) [N/m/?] n
  AudioScience ASIxxxx (SND_ASIHPI) [N/m/?] n
  ATI IXP AC97 Controller (SND_ATIIXP) [N/m/?] n
  ATI IXP Modem (SND_ATIIXP_MODEM) [N/m/?] n
  Aureal Advantage (SND_AU8810) [N/m/?] n
  Aureal Vortex (SND_AU8820) [N/m/?] n
  Aureal Vortex 2 (SND_AU8830) [N/m/?] n
  Emagic Audiowerk 2 (SND_AW2) [N/m/?] n
  Aztech AZF3328 / PCI168 (SND_AZT3328) [N/m/?] n
  Bt87x Audio Capture (SND_BT87X) [N/m/?] n
  SB Audigy LS / Live 24bit (SND_CA0106) [N/m/?] n
  C-Media 8338, 8738, 8768, 8770 (SND_CMIPCI) [N/m/?] n
  C-Media 8786, 8787, 8788 (Oxygen) (SND_OXYGEN) [N/m/?] n
  Cirrus Logic (Sound Fusion) CS4281 (SND_CS4281) [N/m/?] n
  Cirrus Logic (Sound Fusion) CS4280/CS461x/CS462x/CS463x (SND_CS46XX) [N/m/?] n
  Creative Sound Blaster X-Fi (SND_CTXFI) [N/m/?] n
  (Echoaudio) Darla20 (SND_DARLA20) [N/m/?] n
  (Echoaudio) Gina20 (SND_GINA20) [N/m/?] n
  (Echoaudio) Layla20 (SND_LAYLA20) [N/m/?] n
  (Echoaudio) Darla24 (SND_DARLA24) [N/m/?] n
  (Echoaudio) Gina24 (SND_GINA24) [N/m/?] n
  (Echoaudio) Layla24 (SND_LAYLA24) [N/m/?] n
  (Echoaudio) Mona (SND_MONA) [N/m/?] n
  (Echoaudio) Mia (SND_MIA) [N/m/?] n
  (Echoaudio) 3G cards (SND_ECHO3G) [N/m/?] n
  (Echoaudio) Indigo (SND_INDIGO) [N/m/?] n
  (Echoaudio) Indigo IO (SND_INDIGOIO) [N/m/?] n
  (Echoaudio) Indigo DJ (SND_INDIGODJ) [N/m/?] n
  (Echoaudio) Indigo IOx (SND_INDIGOIOX) [N/m/?] n
  (Echoaudio) Indigo DJx (SND_INDIGODJX) [N/m/?] n
  Emu10k1 (SB Live!, Audigy, E-mu APS) (SND_EMU10K1) [N/m/?] n
  Emu10k1X (Dell OEM Version) (SND_EMU10K1X) [N/m/?] n
  (Creative) Ensoniq AudioPCI 1370 (SND_ENS1370) [N/m/?] n
  (Creative) Ensoniq AudioPCI 1371/1373 (SND_ENS1371) [N/m/?] n
  ESS ES1938/1946/1969 (Solo-1) (SND_ES1938) [N/m/?] n
  ESS ES1968/1978 (Maestro-1/2/2E) (SND_ES1968) [N/m/?] n
  ForteMedia FM801 (SND_FM801) [N/m/?] n
  RME Hammerfall DSP Audio (SND_HDSP) [N/m/?] n
  RME Hammerfall DSP MADI/RayDAT/AIO (SND_HDSPM) [N/m/?] n
  ICEnsemble ICE1712 (Envy24) (SND_ICE1712) [N/m/?] n
  ICE/VT1724/1720 (Envy24HT/PT) (SND_ICE1724) [N/m/?] n
  Intel/SiS/nVidia/AMD/ALi AC97 Controller (SND_INTEL8X0) [N/m/?] n
  Intel/SiS/nVidia/AMD MC97 Modem (SND_INTEL8X0M) [N/m/?] n
  Korg 1212 IO (SND_KORG1212) [N/m/?] n
  Digigram Lola (SND_LOLA) [N/m/?] n
  Digigram LX6464ES (SND_LX6464ES) [N/m/?] n
  ESS Allegro/Maestro3 (SND_MAESTRO3) [N/m/?] n
  Digigram miXart (SND_MIXART) [N/m/?] n
  NeoMagic NM256AV/ZX (SND_NM256) [N/m/?] n
  Digigram PCXHR (SND_PCXHR) [N/m/?] n
  Conexant Riptide (SND_RIPTIDE) [N/m/?] n
  RME Digi32, 32/8, 32 PRO (SND_RME32) [N/m/?] n
  RME Digi96, 96/8, 96/8 PRO (SND_RME96) [N/m/?] n
  RME Digi9652 (Hammerfall) (SND_RME9652) [N/m/?] n
  Studio Evolution SE6X (SND_SE6X) [N/m/?] (NEW) n
  S3 SonicVibes (SND_SONICVIBES) [N/m/?] n
  Trident 4D-Wave DX/NX; SiS 7018 (SND_TRIDENT) [N/m/?] n
  VIA 82C686A/B, 8233/8235 AC97 Controller (SND_VIA82XX) [N/m/?] n
  VIA 82C686A/B, 8233 based Modems (SND_VIA82XX_MODEM) [N/m/?] n
  Asus Virtuoso 66/100/200 (Xonar) (SND_VIRTUOSO) [N/m/?] n
  Digigram VX222 (SND_VX222) [N/m/?] n
  Yamaha YMF724/740/744/754 (SND_YMFPCI) [N/m/?] n
#
# configuration written to .config
#
```

Veamos ahora cuantos módulos hay enlazados estáticamente y dinámicamente:

```
egrep '=y' .config | wc -l

1843

egrep '=m' .config | wc -l

4
```

El número se ha reducido considerablemente, desde casi 6000 a unos 1850 módulos. Ahora podremos realizar nuestra primera compilación, que no debería cambiar nada en nuestro sistema ya que los módulos son los que estamos usando actualmente, pero podremos comprobar que no ha ocurrido ningún problema y nuestro sistema arranca como es debido:

```
make -j8 bindeb-pkg
```

Con este comando empezaremos la compilación, indicando con `bindeb-pkg` que cree un paquete .deb en el directorio padre y con `-j` el número de hilos que usaremos en la compilación. Durante la compilación es posible que nos surjan errores de dependencias, por lo que será necesario instalar los paquetes que nos indique y volver a realizar la compilación hasta que finalice correctamente.

Durante la instalación me surgió el siguiente error:

![error_compilacion.png](/images/compilacionkernel/error_compilacion.png)

Este error se soluciona dejando la línea indicada en el fichero *.config* de la siguiente forma:

![solucion_error.png](/images/compilacionkernel/solucion_error.png)

Una vez solucionado ese error, la compilación finalizó exitosamente:

![compilacion_exito.png](/images/compilacionkernel/compilacion_exito.png)

Podemos ver que se han generado los ficheros .deb en el directorio padre:

```
ls -l

total 251624
drwxr-xr-x 25 debian debian      4096 oct 19 19:00 linux-5.14
-rw-r--r--  1 debian debian 120669872 ago 30 07:49 linux-5.14.tar.xz
-rw-r--r--  1 debian debian   8020892 oct 19 19:00 linux-headers-5.14.0_5.14.0-1_amd64.deb
-rw-r--r--  1 debian debian   9197344 oct 19 19:00 linux-image-5.14.0_5.14.0-1_amd64.deb
-rw-r--r--  1 debian debian 118559504 oct 19 19:04 linux-image-5.14.0-dbg_5.14.0-1_amd64.deb
-rw-r--r--  1 debian debian   1184444 oct 19 19:00 linux-libc-dev_5.14.0-1_amd64.deb
-rw-r--r--  1 debian debian      5327 oct 19 19:04 linux-upstream_5.14.0-1_amd64.buildinfo
-rw-r--r--  1 debian debian      2187 oct 19 19:04 linux-upstream_5.14.0-1_amd64.changes
```

Ahora debemos instalar el paquete *linux-image-5.14.0_5.14.0-1_amd64.deb* con `dpkg`:

`
dpkg -i linux-image-5.14.13_5.14.13-1_amd64.deb
`

Se ha creado una nueva configuración en el directorio */boot* y para acceder al nuevo kernel debemos reiniciar la máquina y en *Opciones avanzadas para Debian GNU/Linux* debemos seleccionar el nuevo kernel:

![arranque.png](/images/compilacionkernel/arranque.png)

Si arranca con éxito, significa que hemos compilado e instalado con éxito el kernel. En este caso debería arrancar el sistema de forma normal, ya que realmente no hemos modificado los módulos que el sistema carga. Podemos comprobar el kernel que se está usando:

```
uname -r

5.14.13
```

Como podemos ver, se está usando el nuevo kernel. Una vez que hemos verificado que ha funcionado, vamos a volver a reiniciar la máquina y entrar con el kernel original, para, esta vez sí, dejarlo lo más ligero posible. Antes de volver a compilar el kernel, debemos eliminar los archivos residuales de la compilación anterior, para lo cual usamos el comando `make clean`:

```
make clean
  CLEAN   arch/x86/entry/vdso
  CLEAN   arch/x86/kernel/cpu
  CLEAN   arch/x86/kernel
  CLEAN   arch/x86/purgatory
  CLEAN   arch/x86/realmode/rm
  CLEAN   arch/x86/lib
  CLEAN   certs
  CLEAN   drivers/firmware/efi/libstub
  CLEAN   drivers/scsi
  CLEAN   drivers/tty/vt
  CLEAN   kernel
  CLEAN   lib
  CLEAN   security/apparmor
  CLEAN   security/selinux
  CLEAN   security/tomoyo
  CLEAN   usr/include
  CLEAN   usr
  CLEAN   arch/x86/boot/compressed
  CLEAN   arch/x86/boot
  CLEAN   arch/x86/tools
  CLEAN    resolve_btfids
  CLEAN   vmlinux.symvers modules-only.symvers modules.builtin modules.builtin.modinfo
```

Antes de volver a compilar el paquete, vamos a hacer uso del comando `make xconfig` para abrir una aplicación gráfica que nos facilitará bastante la labor de elegir que módulos añadir y que módulos quitar:

![xconfig.png](/images/compilacionkernel/xconfig.png)


Lo único que queda ahora es repetir el proceso de `make xconfig`, `make clean` e instalar el nuevo paquete generado quitando cada vez más módulos, haciendo pruebas sobre cuales quitar o cuales no, hasta dejar al kernel con una cantidad de módulos que nos parezca adecuada. En mi caso, tras bastantes compilaciones diferentes, el kernel que me quedó tenía el siguiente número de módulos:

```
egrep '=y' .config | wc -l
748

egrep '=m' .config | wc -l
0
```


Si en algún momento nos cansamos del kernel que hemos instalado, desinstalarlo es tan fácil como usar el siguiente comando:

`
apt-get purge linux-image-5.14.13
`
