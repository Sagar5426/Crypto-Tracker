# 💰 Crypto Tracker

A modern iOS app built with **SwiftUI** and **Combine**, following a clean **MVVM architecture** for clarity, scalability, and testability.  
Powered by real-time data from the **[CoinGecko API](https://www.coingecko.com/en/api)**.

---

## 🚀 Overview

**Crypto Tracker** allows users to explore, monitor, and stay updated with cryptocurrency prices in real time — all through a sleek, responsive SwiftUI interface.  
It’s designed with a strong architectural foundation to ensure smooth data flow, high maintainability, and ease of testing.

---

## 🖼️ Screenshots

<img width="300" alt="Screenshot 1" src="https://github.com/user-attachments/assets/c4932a15-99e4-454f-a7c5-fdac2e47e4e8" />
<img width="300" alt="Screenshot 2" src="https://github.com/user-attachments/assets/13f23595-4256-4cf5-af2f-f11708839cb4" />
<img width="300" alt="Screenshot 3" src="https://github.com/user-attachments/assets/a0be3521-d740-4c59-a0a8-1cb9afc0b41b" />
<img width="300" alt="Screenshot 4" src="https://github.com/user-attachments/assets/85ba5eea-193d-43de-9694-563010abf373" />
<img width="300" alt="Screenshot 5" src="https://github.com/user-attachments/assets/70df3666-166a-4bd2-91f4-12854513bd0d" />

---

## 🎥 Screen Recording

[Watch the demo →](https://github.com/user-attachments/assets/eb762127-37f2-4aaf-8414-5196a4f6617b)

---

## 🧠 Tech Stack

- **Swift** — Core language  
- **SwiftUI** — Declarative UI framework  
- **Combine** — Reactive data pipelines  

---

## 🏗️ Architecture

**MVVM Pattern**

- **Views** — Display app state through reactive bindings.  
- **ViewModels** — Manage business logic, expose data via `@Published` properties.  
- **Services** — Handle networking and persistence using protocol-driven design for easy testing and dependency injection.  

**Key Principles**

- Clear separation of concerns  
- Scalable and testable codebase  
- Reactive updates using Combine  
- Mock-friendly architecture for unit testing  

---

## 🔄 Data Flow

**User Input → View → ViewModel → Services → ViewModel (Outputs via Combine) → View**

This unidirectional data flow ensures smooth reactive updates, debounced UI rendering, and main-thread safety.

---

## ✨ Highlights

- ✅ Real-time crypto data powered by **CoinGecko API**  
- ⚡ Debounced search and smooth UI updates  
- 🧩 Testable ViewModels with mockable services  
- 💡 Lightweight, modular SwiftUI components  
- 🔧 Protocol-oriented design for flexibility  

---

## 🧩 Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/Sagar5426/Crypto-Tracker.git
