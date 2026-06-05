# 🤝 Contributing to Unplugged

Thank you for your interest in contributing to Unplugged! Follow these guidelines to ensure a smooth contribution process.

---

## 🛠️ Development Setup

1. **Fork & Clone**:
   ```bash
   git clone https://github.com/your-username/Unplugged.git
   cd Unplugged
   ```

2. **Generate the Project**:
   We generate the Xcode project dynamically. Run the generator script:
   ```bash
   ruby generate_xcodeproj.rb
   ```

3. **Open Xcode**:
   ```bash
   open Unplugged.xcodeproj
   ```

4. **Signing & Certificates**:
   Select the **Unplugged** target, go to **Signing & Capabilities**, and set your development **Team** (Free or Paid Apple Developer Account).

---

## 🧑‍💻 Code Contribution Flow

1. **Create a Feature Branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```
2. **Implement Changes**:
   * Adhere to Swift API Design Guidelines.
   * Confine UI/State changes to the `@MainActor` as designed.
   * Write clean, self-documenting code.
3. **Regenerate Xcode Project (If files added/removed)**:
   If you add new `.swift` files, run `ruby generate_xcodeproj.rb` again to verify file list references match.
4. **Commit & Push**:
   Keep commits logical and structured:
   ```bash
   git commit -m "Implement feature description"
   git push origin feature/your-feature-name
   ```
5. **Open a Pull Request (PR)**:
   * Target the `main` branch.
   * Describe changes, context, and testing performed.

---

## 🐞 Reporting Bugs & Requesting Features

* **Bugs**: Open an issue specifying your macOS version, device type (Apple Silicon / Intel), reproduction steps, and expected vs actual behavior.
* **Features**: Clearly describe the proposed capability, target audience, and optional API design.
