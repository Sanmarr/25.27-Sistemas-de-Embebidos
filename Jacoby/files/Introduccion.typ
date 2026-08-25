= Introducción a los Microcontroladores

/*
#figure(
  image("/images/intro.png", width: 30%)
) <fig:indice>
*/
== Integración y SoC
Históricamente, los sistemas microprocesados requerían múltiples integrados (CPU, RAM, ROM, Clock, etc.) . Los *Microcontroladores (MCU)* actuales integran todos estos bloques en un solo chip, conocido como *System on Chip* (SoC) :
-  *CPU:* Microprocesador central.
-  *Memoria:* RAM para datos y Flash/ROM para programa.
-  *Periféricos:* Módulos de hardware (Timers, ADC, UART) configurables mediante registros que funcionan en paralelo a la CPU, permitiendo multitarea real .

== Clasificación de MCUs
Se eligen y distinguen principalmente por :
- *CPU:* Arquitecturas de 8, 16 o 32 bits.
- *Memoria:* Cantidad de RAM y FLASH disponible.
- *Encapsulado:* Número y tipo de pines físicos.
- *Aplicación:* Bajo costo, alta performance o bajo consumo (*Low Power*).

== Conexionado y Funcionamiento Básico
- *Alimentación:* Pines VDD y GND. La tendencia actual es bajar la tensión (3.3V, 1.8V) para reducir el consumo .
- *Clock:* Provee la señal de sincronismo. Muchos poseen PLL internos para multiplicar la frecuencia del oscilador .
- *Reset:* Asegura que el programa inicie desde una condición predefinida (pin nRESET) .
- *Entradas/Salidas (I/O):*
-  *GPIO:* Pines digitales configurables (entrada/salida, pull-up/down, etc.) .
-  *Analógicos:* Conversores A/D y D/A para el mundo real .

== Consumo y Energía
El consumo se divide en potencia estática y dinámica, dominando generalmente la *dinámica* . Es fundamental el uso de modos *Sleep* para ahorrar energía en sistemas a batería, teniendo en cuenta que a menor consumo, mayor es el tiempo de despertar (*wakeup*).

== Ecosistema de Desarrollo
Para trabajar con un MCU se requiere [19-22]:
+ *Documentación:* Datasheet y Reference Manual.
+ *Evaluation Board:* Placa de desarrollo con el MCU.
+ *Toolchain:* IDE, compilador y programador/debugger.
+ *SDK:* Librerías y ejemplos de código.

== Introducción a Kinetis K64F

=== La Familia Kinetis
Kinetis es una familia de microcontroladores de *32 bits de NXP* basada en el núcleo *ARM Cortex-M* . 

=== Microcontrolador K64
El modelo específico de estudio es el *MK64FN1M0VLL12* . Sus características principales son :
- *Core:* ARM Cortex-M4 a 120 MHz con FPU (Unidad de Punto Flotante).
- *Memoria:* 1 MB de Flash y 256 KB de SRAM.
- *Encapsulado:* 100 LQFP.

=== Placa de Evaluación: FRDM-K64F
Es una plataforma de bajo costo que incluye :
- *Conectividad:* Ethernet, USB (Host/Device) y slot para MicroSD (SDHC).
- *Sensores:* Acelerómetro y magnetómetro integrados.
- *Interfaz Humana:* LED RGB y 2 pulsadores (SW2 y SW3).
- *Depuración:* Programador incorporado *OpenSDAv2*.

=== Toolchain: MCUXpresso
El IDE oficial de NXP para esta plataforma es *MCUXpresso*, basado en Eclipse . Para su funcionamiento con la familia K64, es indispensable instalar el *SDK específico* de la placa FRDM-K64F .

#box(stroke: 1pt, inset: 10pt)[
  *Nota sobre Registros:* El control de los periféricos en el K64 se realiza mediante la escritura en registros de 32 bits, como el *Pin Control Register* (PCR), que define la multiplexación (MUX) y características eléctricas de cada pin .
]