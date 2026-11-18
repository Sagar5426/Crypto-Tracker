
# 💰 CoinPilot

A modern iOS app built with **SwiftUI** and **Combine**, following a clean **MVVM architecture** for clarity, scalability, and testability.  
Powered by real-time data from the **[CoinGecko API](https://www.coingecko.com/en/api)**.

---

## 🚀 Overview

**CoinPilot** allows users to explore, monitor, and stay updated with cryptocurrency prices in real time — all through a sleek, responsive SwiftUI interface.  
It’s designed with a strong architectural foundation to ensure smooth data flow, high maintainability, and ease of testing.

---

## 🖼️ Screenshots

<img width="300" alt="IMG_2848" src="https://github.com/user-attachments/assets/a7e08c93-1ff2-445b-a670-6c0539704f3c" />
<img width="300" alt="IMG_2849" src="https://github.com/user-attachments/assets/8576fc70-d422-4f47-8db4-3d45f50047da" />
<img width="300" alt="IMG_2850" src="https://github.com/user-attachments/assets/10886745-d9a3-4810-9825-22d74de86540" />
<img width="300" alt="IMG_2851" src="https://github.com/user-attachments/assets/7d9e2e2d-33c5-4d99-9bd7-320b24bab7ad" />
<img width="300" alt="IMG_2852" src="https://github.com/user-attachments/assets/8a031726-f0a0-4e7b-91a4-a3598397b959" />
<img width="300" alt="IMG_2853" src="https://github.com/user-attachments/assets/3b2ffb48-c562-4523-91ca-47e29f2af368" />
<img width="300" alt="IMG_2854" src="https://github.com/user-attachments/assets/c5230a45-dcc8-41f0-82b4-b3264cdcb139" />
<img width="300" alt="IMG_2855" src="https://github.com/user-attachments/assets/7effe97f-739a-4ff4-96b1-0c52ebda5522" />
<img width="300" alt="IMG_2856" src="https://github.com/user-attachments/assets/3ea9324f-8fd9-4f24-81fa-f71c1bf87f28" />
<img width="300" alt="IMG_2857" src="https://github.com/user-attachments/assets/fe77ad4a-dd15-4374-a78a-b939f24953c8" />
<img width="300" alt="IMG_2858" src="https://github.com/user-attachments/assets/94c47c87-cd2c-441d-945d-cc28d2a844d7" />
<img width="300" alt="IMG_2859" src="https://github.com/user-attachments/assets/ec4c2a42-bf6d-43fc-9ee3-baf22f97dcb0" />
<img width="300" alt="IMG_2860" src="https://github.com/user-attachments/assets/d65abd7c-4bbc-42c7-84e8-593f1b91a12a" />
<img width="300" alt="IMG_2861" src="https://github.com/user-attachments/assets/a27c47d0-b409-4786-87c1-4593dc395b45" />
<img width="300" alt="IMG_2862" src="https://github.com/user-attachments/assets/e8aaaa1f-e3d6-43fc-9eb2-78fb77277763" />
<img width="300" alt="IMG_2863" src="https://github.com/user-attachments/assets/f31ddb76-8917-471c-9343-a5b76b4f7a82" />
<img width="300" alt="IMG_2864" src="https://github.com/user-attachments/assets/b29977d8-425a-4eae-9c93-261f3ebc62c5" />
<img width="300" alt="IMG_2865" src="https://github.com/user-attachments/assets/475c2c4a-5c8e-46cc-a395-545c24364f56" />



---

## 🎥 Screen Recording

[Watch the demo →](https://youtube.com/shorts/SzIfOeg4r6o?si=r5leAdfasmI7t96M)

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
   git clone https://github.com/Sagar5426/CoinPilot.git
   ```
