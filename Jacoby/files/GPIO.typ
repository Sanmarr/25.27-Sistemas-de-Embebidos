= Conceptos Generales de GPIO

Los puertos de *Entrada/Salida de Propósito General (GPIO)* permiten al microcontrolador interactuar con el mundo exterior . A través de estos pines, el MCU puede detectar eventos (entradas) o generar cambios (salidas) en periféricos como sensores, pulsadores, LEDs o motores.

== Estructura Interna de un Pin
Un pin GPIO suele incluir componentes clave para su funcionamiento:
- *Buffers Tri-state:* Permiten que el pin sea bidireccional, controlando el flujo de datos hacia adentro o hacia afuera.
- *Resistencias de Pull-up/Pull-down:* Evitan el estado de *entrada flotante*, asegurando un nivel lógico definido (0 o 1) cuando no hay una señal externa conectada .
- *Multiplexación:* Un mismo pin físico puede tener múltiples funciones alternativas (ADC, UART, SPI, etc.), seleccionables por software .

= GPIO en el Microcontrolador K64

El microcontrolador K64 cuenta con *5 puertos (PORTA a PORTE)* de 32 bits cada uno [3]. El acceso a estos puertos se divide en dos capas: la capa de control de puerto (*PORT*) y la capa de datos (*GPIO*) .

=== Registros de Datos (GPIO)
El manejo de los niveles lógicos se realiza mediante registros específicos de 32 bits:
- *PDOR (Port Data Output Register):* Almacena el valor que se enviará a los pines configurados como salida .
- *PSOR, PCOR y PTOR:* Registros para *poner en 1 (Set)*, *limpiar (Clear)* o *conmutar (Toggle)* bits individuales del PDOR de forma eficiente .
- *PDIR (Port Data Input Register):* Permite leer el estado lógico actual de los pines .
- *PDDR (Port Data Direction Register):* Configura si cada pin actúa como *entrada (0)* o *salida (1)* .

=== Registro de Control de Pin (PCR)
Cada pin tiene su propio registro *PCR* de 32 bits que define sus características eléctricas y funcionales :
- *MUX (bits 10-8):* Selecciona la función del pin (ej. ALT1 es GPIO) .
- *DSE (Drive Strength):* Configura la capacidad de corriente de salida (alta o baja) .
- *SRE (Slew Rate):* Controla la velocidad de transición de la señal para reducir interferencias .
- *PE y PS:* Habilitan y seleccionan la resistencia interna de Pull-up o Pull-down .
- *IRQC:* Configura la generación de *interrupciones* (por flanco o nivel) .

=== Control Global y Clock Gating
- *Registros Globales (GPCLR/GPCHR):* Permiten configurar múltiples PCRs de un puerto simultáneamente con una sola escritura [8].
- *Reloj de Periférico:* Antes de utilizar cualquier puerto, es obligatorio habilitar su señal de reloj mediante el registro *SIM->SCGC5* [9].

== Bit-Banding

El *Bit-Banding* es un mecanismo de los núcleos Cortex-M3/M4 que permite modificar bits individuales de forma *atómica* .

=== Funcionamiento y Mapeo
Este mecanismo mapea cada bit de una región de memoria (1 MB) a una palabra completa (32 bits) en una región llamada *Alias Region* (32 MB) :
- Escribir el bit menos significativo en una palabra del *Alias* modifica directamente el bit correspondiente en la región de *Bit-band* .
- Esto elimina la necesidad de realizar operaciones de tipo *Lectura-Modificación-Escritura (RMW)*, evitando conflictos cuando ocurren interrupciones en medio de la operación .

=== Regiones en K64F
Existen dos zonas principales habilitadas para bit-banding en el K64F :
+ *SRAM_U:* Región de memoria RAM.
+ *Peripherals:* Región donde se encuentran los registros de los periféricos y GPIO .

#box(stroke: 1pt, inset: 10pt)[
  *Importante:* Para los puertos GPIO del K64, aunque existe la región de Bit-Band Alias (0x4200_0000), el hardware ya provee registros atómicos como PSOR y PCOR para manipular bits de salida de manera segura.
]