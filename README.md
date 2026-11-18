# 💰 CoinPilot

A modern iOS cryptocurrency trading simulator built with **SwiftUI** and **Combine**, following a clean **MVVM architecture** for clarity, scalability, and testability.

Powered by real-time cryptocurrency data from the **[CoinGecko API](https://www.coingecko.com/en/api)**.

---

## 🚀 Overview

**CoinPilot** allows users to explore cryptocurrency markets, monitor price movements, manage a virtual portfolio, and simulate buying and selling cryptocurrencies using virtual funds.

It combines real-time market data with portfolio tracking and trading features, all within a sleek and responsive SwiftUI interface.

---

## 🖼️ Screenshots

### 📈 Market View

Explore cryptocurrency prices, market trends, and real-time market information.

<p align="left">
  <img width="220" alt="Market View" src="https://github.com/user-attachments/assets/a7e08c93-1ff2-445b-a670-6c0539704f3c" />
</p>

### 🪙 Coin Details

View detailed cryptocurrency information, price movements, and individual coin statistics.

<table>
  <tr>
    <td align="center">
      <img width="220" alt="Coin Detail View 1" src="https://github.com/user-attachments/assets/8576fc70-d422-4f47-8db4-3d45f50047da" />
    </td>
    <td align="center">
      <img width="220" alt="Coin Detail View 2" src="https://github.com/user-attachments/assets/10886745-d9a3-4810-9825-22d74de86540" />
    </td>
  </tr>
</table>

### 💼 Portfolio

Track portfolio performance, holdings, invested value, and overall returns.

<table>
  <tr>
    <td align="center">
      <img width="220" alt="Portfolio View 1" src="https://github.com/user-attachments/assets/7d9e2e2d-33c5-4d99-9bd7-320b24bab7ad" />
    </td>
    <td align="center">
      <img width="220" alt="Portfolio View 2" src="https://github.com/user-attachments/assets/8a031726-f0a0-4e7b-91a4-a3598397b959" />
    </td>
    <td align="center">
      <img width="220" alt="Portfolio View 3" src="https://github.com/user-attachments/assets/3b2ffb48-c562-4523-91ca-47e29f2af368" />
    </td>
  </tr>
</table>

### 📊 Coin Holding Breakdown

Get a detailed breakdown of individual cryptocurrency holdings and their contribution to the portfolio.

<p align="left">
  <img width="220" alt="Coin Holding Breakdown" src="https://github.com/user-attachments/assets/c5230a45-dcc8-41f0-82b4-b3264cdcb139" />
</p>

### ⭐ Watchlist

Keep track of favorite cryptocurrencies and monitor their market performance in one place.

<table>
  <tr>
    <td align="center">
      <img width="220" alt="Watchlist View 1" src="https://github.com/user-attachments/assets/7effe97f-739a-4ff4-96b1-0c52ebda5522" />
    </td>
    <td align="center">
      <img width="220" alt="Watchlist View 2" src="https://github.com/user-attachments/assets/3ea9324f-8fd9-4f24-81fa-f71c1bf87f28" />
    </td>
    <td align="center">
      <img width="220" alt="Watchlist View 3" src="https://github.com/user-attachments/assets/fe77ad4a-dd15-4374-a78a-b939f24953c8" />
    </td>
  </tr>
</table>

### ⚙️ Settings, Wallet & Trading Activity

Manage virtual wallet funds, review profit and loss, and access trading history through the settings section.

<table>
  <tr>
    <td align="center">
      <img width="220" alt="Settings View 1" src="https://github.com/user-attachments/assets/94c47c87-cd2c-441d-945d-cc28d2a844d7" />
    </td>
    <td align="center">
      <img width="220" alt="Settings View 2" src="https://github.com/user-attachments/assets/ec4c2a42-bf6d-43fc-9ee3-baf22f97dcb0" />
    </td>
    <td align="center">
      <img width="220" alt="Settings View 3" src="https://github.com/user-attachments/assets/d65abd7c-4bbc-42c7-84e8-593f1b91a12a" />
    </td>
  </tr>
  <tr>
    <td align="center">
      <img width="220" alt="Settings View 4" src="https://github.com/user-attachments/assets/a27c47d0-b409-4786-87c1-4593dc395b45" />
    </td>
    <td align="center">
      <img width="220" alt="Settings View 5" src="https://github.com/user-attachments/assets/e8aaaa1f-e3d6-43fc-9eb2-78fb77277763" />
    </td>
    <td align="center">
      <img width="220" alt="Settings View 6" src="https://github.com/user-attachments/assets/f31ddb76-8917-471c-9343-a5b76b4f7a82" />
    </td>
  </tr>
  <tr>
    <td align="center">
      <img width="220" alt="Settings View 7" src="https://github.com/user-attachments/assets/b29977d8-425a-4eae-9c93-261f3ebc62c5" />
    </td>
    <td align="center">
      <img width="220" alt="Settings View 8" src="https://github.com/user-attachments/assets/475c2c4a-5c8e-46cc-a395-545c24364f56" />
    </td>
    <td></td>
  </tr>
</table>

---

## 🎥 Screen Recording

[Watch the demo →](https://youtube.com/shorts/SzIfOeg4r6o?si=r5leAdfasmI7t96M)

---

## 🧠 Tech Stack

- **Swift** — Core programming language
- **SwiftUI** — Declarative UI framework
- **Combine** — Reactive data pipelines
- **CoinGecko API** — Real-time cryptocurrency market data

---

## 🏗️ Architecture

**MVVM Pattern**

- **Views** — Display app state through reactive bindings.
- **ViewModels** — Manage business logic and expose data through `@Published` properties.
- **Services** — Handle networking and persistence using protocol-driven design for testing and dependency injection.

**Key Principles**

- Clear separation of concerns
- Scalable and testable codebase
- Reactive updates using Combine
- Mock-friendly architecture for unit testing

---

## 🔄 Data Flow

**User Input → View → ViewModel → Services → ViewModel (Outputs via Combine) → View**

This unidirectional data flow ensures smooth reactive updates, organized business logic, and main-thread-safe UI rendering.

---

## ✨ Highlights

- ✅ Real-time cryptocurrency data powered by **CoinGecko API**
- 💱 Simulated cryptocurrency buying and selling using virtual funds
- 💼 Portfolio and individual holding tracking
- 📊 Profit and loss tracking
- ⭐ Cryptocurrency watchlist
- ⚡ Debounced search and smooth UI updates
- 🧩 Testable ViewModels with mockable services
- 💡 Lightweight, modular SwiftUI components
- 🔧 Protocol-oriented design for flexibility

---

## 🧩 Getting Started

1. **Clone the repository**

   ```bash
   git clone https://github.com/Sagar5426/CoinPilot.git
