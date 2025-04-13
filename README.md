# 🖥️ CHR Installation Script for Ubuntu Server

A simple shell script to automate the installation of **MikroTik Cloud Hosted Router (CHR)** on **Ubuntu Server**.  
This script helps you deploy CHR quickly and efficiently from the command line without manual configuration.

---

## 📦 Repository Contents

| File             | Description                                |
|------------------|--------------------------------------------|
| `chr-install.sh` | Main shell script to install CHR on Ubuntu Server |

---

## 🚀 How to Use

There are two ways to run the script, depending on your preference:

---

## Before run the script

make sure you're in root user:

```bash
sudo su
```

### 🔹 Option 1: Run Directly from GitHub (Quick & Easy)

This method is ideal if you want to execute the script instantly without cloning the repository.

#### Using `curl`

```bash
bash <(curl -s https://raw.githubusercontent.com/manggiperdana/CHR-Ubuntu-server/main/chr-install.sh)
```
### 🔹 Option 2: Clone the Repository First (Recommended for Review or Customization)

This method is better if you want to inspect or modify the script beforehand.

#### Steps
1.	Clone the repository:
```bash
git clone https://github.com/manggiperdana/CHR-Ubuntu-server.git
cd CHR-Ubuntu-server
```
2.	Make the script executable and run it:
```bash
chmod +x chr-install.sh
./chr-install.sh
```

## 📄 License

This project is licensed under the MIT License.

You are free to use, modify, and distribute this script.
Please note that it is provided as-is without any warranty.
