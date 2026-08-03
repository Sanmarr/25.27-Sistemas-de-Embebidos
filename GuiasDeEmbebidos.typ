#set document(
  author: "Ignacio Sammartino",
  description: 
    "Resumen de Organizacion Industrial",
  keywords: "2P", 
  date: auto
)

#set text(lang: "es")


//Seteo el formato del texto
#set text(
  font: "Linux Biolinum O",
  size: 12pt,
  tracking: 0pt, // (Default = 0pt2)
  spacing: 100%,
  fractions: false /* Se rompe por algun motivo con true*/
)

//Formato del titulo
#show title: set text(size: 20pt)
#show title: set align(center)
#show title: set block(below: 4em)

#align(center)[#text(size: 24pt)[Instituto Tecnológico de Buenos Aires (ITBA)]] 

#figure(
  image("images/itbaSVG_black.svg", width: 80%)
) <fig:indice>

#title[
25.27 - Sistemas Embebidos

Guias
]

Ignacio Sammartino
#set page(
  header: context [
    #grid(
      columns: (1fr, auto),
      align: center,
      [#align(left)[25.27 - Sistemas Embebidos ]],
      [#align(right)[#image("images/itbaSVG.svg", width: 33%)]]
    )
  ],
  numbering: "1 of 1",
  columns: 1,
)

#set page(
  margin: (
  top: 3cm,
  bottom: 2cm,
  x: 0.8cm,
))

#set page(numbering: "1 of 1")
#set heading(numbering: "1. 1. 1 -")

#pagebreak()
#set page(columns: 2)
#outline()
#set page(columns: 1)

#pagebreak()
#include "files/Guia1.typ"