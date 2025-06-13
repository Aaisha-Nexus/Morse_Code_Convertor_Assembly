# IDDY UMPTY CONVERTER (MORSE ENCODER)

## 🔍 Overview

**IDDY UMPTY CONVERTER** is a Morse Code Encoder built entirely in Assembly language using MASM (Microsoft Macro Assembler) and executed via DOSBox. The goal is to revive the timeless Morse code system through a low-level programming approach, highlighting its ongoing relevance in fields like space missions, aviation, cyber encryption, and emergency signaling.

---

## 🌟 Inspiration

Morse code is one of the earliest forms of digital communication. Despite modern advances like Artificial Intelligence, this simple and elegant encoding method remains useful in critical domains.  
Our motivation for this project stemmed from:

- The historical and technical importance of Morse code
- Its real-world applications even today (e.g., space, military, aviation, assistive tech)
- The educational opportunity to use Assembly, diving deep into how memory, strings, and I/O are handled at the hardware level

We were driven by the idea of blending old-school communication with low-level coding — and witnessing how much control and creativity can be achieved in such a raw, fundamental language.

---

## 🛠️ Project Description

This program is a **Morse Code Encoder** that:

- Accepts alphanumeric user input (A–Z, 0–9)
- Translates each character to its Morse code equivalent
- Displays the output as a series of dots `.` and dashes `-`
- Uses efficient string traversal and memory mapping via Assembly language
- Optionally integrates **audible beeps** for each Morse symbol

> ⚙️ Developed using MASM and run in a DOSBox environment 

---

## 📂 How It Works

- A **lookup table** maps each valid ASCII character to its Morse representation using `DB` directives.
- A loop processes each input character, converting it through the table.
- Output is handled via interrupt services to display Morse symbols on the screen.
- A future extension allows **sound generation** for each dot/dash via system beeps for a more interactive experience.

---

## 🧠 Concepts Demonstrated

- Low-level memory management  
- String manipulation in Assembly  
- Efficient use of interrupt calls (`INT 21h`)  
- Table-driven encoding with `DB`  
- Real-time user interaction via command line  
- Optional: hardware interaction for audio signals  

---


## 👥 Contributors

- https://github.com/minalDev-git
- Javeria Amir
- Rida Fatima
- Zobiah Saleem
- Rabeaa Hussain
- Haleema Fatima

---

## 🧪 Requirements

- MASM (Microsoft Macro Assembler)  
- DOSBox or similar DOS emulator  
- Basic understanding of Assembly Language (x86 architecture)

---
