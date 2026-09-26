// =====================================================================
// RESUMEN DIDÁCTICO - CLASE 1: BUSES Y GPIO EN SISTEMAS EMBEBIDOS
// Asignatura: 25.27 - Sistemas Embebidos (ITBA)
// Autor apunte original: Ignacio Sammartino
// Formato: Typst 0.13+ / 0.14 / 0.15 (Compilable)
// =====================================================================

#set document(
  title: [Resumen Didáctico Clase 1 - Buses y GPIO],
  author: "Ignacio Sammartino",
  description: "Apunte Sistemas Embebidos (ITBA)",
  keywords: ("sistemas embebidos", "gpio", "k64f", "buses", "typst", "itba")
)

// Configuración global de texto e idioma
#set text(
  lang: "es",
  region: "AR",
  size: 10pt,
  font: "Liberation Sans"
)

// Configuración de página con encabezado y pie estilizado
#set page(
  paper: "a4",
  margin: (top: 2.2cm, bottom: 2cm, x: 1.8cm),
  header: context [
    #grid(
      columns: (1fr, auto),
      align: horizon,
      [
        #text(weight: "bold", fill: rgb("#1a3a6b"))[25.27 - Sistemas Embebidos]
        #h(0.8em) | #h(0.8em)
        #text(style: "italic", fill: luma(80))[Resumen]
      ],
      [
        #text(size: 8.5pt, weight: "bold", fill: rgb("#1a3a6b"))[ITBA]
      ]
    )
    #v(2pt)
    #line(length: 100%, stroke: 0.8pt + rgb("#1a3a6b"))
  ],
  footer: context [
    #line(length: 100%, stroke: 0.4pt + luma(200))
    #v(2pt)
    #grid(
      columns: (1fr, 1fr),
      align(left)[#text(size: 8pt, fill: luma(120))[Instituto Tecnológico de Buenos Aires]],
      align(right)[#text(size: 8.5pt, weight: "bold", fill: luma(100))[Página #counter(page).display("1 / 1", both: true)]]
    )
  ],
  numbering: "1 / 1"
)

#set par(justify: true, leading: 0.65em)
#set heading(numbering: "1.1")

// Personalización estilizada de los títulos
#show heading.where(level: 1): it => block(
  width: 100%,
  fill: rgb("#eef3f8"),
  inset: (x: 10pt, y: 8pt),
  radius: 4pt,
  stroke: (left: 4pt + rgb("#1a3a6b")),
  above: 1.6em,
  below: 1em,
)[
  #text(size: 13pt, weight: "bold", fill: rgb("#1a3a6b"))[#it.body]
]

#show heading.where(level: 2): it => block(
  above: 1.3em,
  below: 0.7em,
)[
  #text(size: 11pt, weight: "bold", fill: rgb("#2b5b84"))[#it.body]
  #v(2pt)
  #line(length: 100%, stroke: 0.5pt + rgb("#cbd5e1"))
]

#show heading.where(level: 3): it => text(size: 10pt, weight: "bold", fill: rgb("#334155"))[#it.body]

// Estilos de bloques de código
#show raw.where(block: true): set block(
  fill: rgb("#f8fafc"),
  stroke: 0.5pt + rgb("#cbd5e1"),
  inset: 8pt,
  radius: 4pt,
  width: 100%
)
#show raw.where(block: false): it => highlight(
  fill: rgb("#f1f5f9"),
  extent: 1.5pt,
  radius: 2pt,
  it
)



// =====================================================================
// PORTADA Y ENCABEZADO PRINCIPAL
// =====================================================================



#align(center)[
  #text(size: 18pt, weight: "bold", fill: rgb("#1a3a6b"))[Instituto Tecnológico de Buenos Aires (ITBA)] \
  #v(0.3em)
  #figure(
  image("/images/itbaSVG_black.svg", width: 40%)
  ) <fig:indice>
  #text(size: 14pt, weight: "bold", fill: rgb("#2b5b84"))[25.27 - Sistemas Embebidos] \
  #v(0.2em)
  #text(size: 12pt, style: "italic", fill: luma(80))[Resumen] \
  #v(0.5em)
  #box(
    fill: rgb("#eef3f8"),
    inset: (x: 12pt, y: 6pt),
    radius: 4pt,
    stroke: 0.5pt + rgb("#1a3a6b")
  )[
    #text(size: 9pt, weight: "bold")[Apunte teórico-práctico basado en el contenido de clase y bibliografía oficial]
  ]
]

#v(1em)

#outline()

#v(1em)

#pagebreak()
#include "files/Clase1.typ"

#pagebreak()
#include "files/Clase2.typ"

#pagebreak()
#include "files/Clase3.typ"

#pagebreak()
#include "files/Clase4.typ"

#pagebreak()
#include "files/Clase5.typ"

#pagebreak()
#include "files/Clase6.typ"