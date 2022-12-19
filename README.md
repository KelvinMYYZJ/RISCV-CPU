# RISCV-CPU 2022
## Design

### General Design
The general idea is to base the whole CPU
on [the stimulator written in c++](https://github.com/KelvinMYYZJ/RISCV) ([see the **ugle** original design here](README.assets/ppca_cpu_structure.jpg)) and use extra parts to make it more **REAL**.

![CPU design](README.assets/design.jpg)

### Reverse station & Load-Store Buffer
In my design, the RS serve as both traditional RS and LS Buffer. This may cause RS be filled with memory access so I use a counter to make sure the number of memory access instructions under a certain value (it is now $4$).