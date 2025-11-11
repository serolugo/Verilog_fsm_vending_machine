# Vending Machine – Verilog (FSM)

This project implements a digital **vending machine** using **Verilog HDL**.  
Its behavior is modeled with a **4-state finite state machine (FSM)** that supports coin handling, product selection, purchase, cancellation, dispensing, and pickup confirmation.

---

## Overview

The vending machine accepts coins, compares credit with product price, returns change when appropriate, and activates a motor to simulate product dispensing.  
A pickup confirmation signal ensures the cycle completes before returning to idle.

The design includes:
- Product selection
- Start / buy / cancel controls
- Credit accumulation (0–9)
- Change calculation
- Motor activation with timed output
- Display of credit and change via 7-segment decoders
- Pickup confirmation

A SystemVerilog testbench validates the behavior under multiple usage scenarios.

---

## FSM

The controller uses **four states**:

| State | Code | Description |
|-------|------|-------------|
| **IDLE** | `00` | System waits for start. Clears change when beginning a new purchase. |
| **COINS** | `01` | Accepts coins (up to 9). Cancel returns all credit. |
| **DISP** | `10` | Calculates change, starts motor, and transitions to pickup. |
| **PICK** | `11` | Waits for motor completion and user pickup signal. |

### State transitions
- `IDLE → COINS` : start
- `COINS → DISP` : buy with credit ≥ price
- `COINS → IDLE` : cancel → full refund
- `DISP → PICK`
- `PICK → IDLE` : pickup confirmed

---

## Product Pricing

| Product | Selector (`sw`) | Price |
|---------|-----------------|-------|
| A | `00` | 4 |
| B | `01` | 9 |
| C | `10` | 2 |
| D | `11` | 7 |

- Coins are worth 1 unit each
- Maximum credit = 9

---

## Architecture

The design is divided into three main modules:

### Top module
Interfaces with:
- `clk`, `rst`
- Buttons: start / coin / buy / cancel (active-low)
- Product selector (`sw`)
- Pickup confirmation (`collected`)

Outputs include:
- Credit + change in BCD → 7-segment format
- LED indicators:
  - Motor
  - Current FSM state
  - Button echo
  - Pickup echo

---

### FSM module
Implements the system behavior:
- Credit accumulation
- Price lookup
- Purchase
- Change calculation
- Cancel handling
- Motor timing
- Pickup verification

Internal logic tracks:
- `credit` (0–9)
- `change`
- Motor timer

---

### BCD to 7-segment
Converts BCD values for display of:
- Current credit
- Change returned

---

## Testbench

A SystemVerilog testbench validates:
1) **Exact credit** → successful purchase
2) **Extra credit** → purchase + correct change
3) **Insufficient credit** → no purchase
4) **Cancel** → full refund and return to idle

Verification uses both waveform inspection and console logs to validate:
- State progression
- Credit + change tracking
- Motor timing
- Pickup behavior

---

## Summary

This project demonstrates a functional vending-machine implementation using a 4-state FSM in Verilog.  
It illustrates:
- FSM-driven sequencing
- Proper handling of buy/cancel flows
- Safe coin accumulation
- Change computation
- Timed output activation
- User pickup confirmation
- Modular HDL design + testbench verification

