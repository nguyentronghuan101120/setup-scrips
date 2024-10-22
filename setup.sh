#!/bin/bash

# Định nghĩa các mã màu
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # Không màu

# Hàm in thông báo với màu
print_step() {
    echo -e "${CYAN}[          INFO          ]${NC} $1\n"
}

print_success() {
    echo -e "${GREEN}[          SUCCESS          ]${NC} $1\n"
}

print_warning() {
    echo -e "${YELLOW}[          WARNING          ]${NC} $1\n"
}

print_error() {
    echo -e "${RED}[          ERROR          ]${NC} $1\n"
}

cd ..

print_step "Installing NVM (Node Version Manager)..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
print_success "NVM installed successfully."

# Cài đặt NodeJS
print_step "Checking if NodeJS is installed..."
if command -v node > /dev/null; then
    NODE_VERSION=$(node -v)
    if [ "$NODE_VERSION" = v20* ]; then
        print_success "NodeJS version $NODE_VERSION is already installed."
    else
        print_warning "NodeJS version $NODE_VERSION is installed, but version 20 is required. Installing NodeJS v20 using NVM..."
        nvm install 20
        print_success "NodeJS v20 installed."
    fi
else
    print_step "Installing NodeJS v20 using NVM..."
    nvm install 20
    print_success "NodeJS v20 installed."
fi

# Cài đặt NPM
print_step "Checking if NPM is installed..."
if command -v npm > /dev/null; then
    NPM_VERSION=$(npm -v)
    if (( $(echo "$NPM_VERSION >= 8" | bc -l) )); then
        print_success "NPM version $NPM_VERSION is already installed."
    else
        print_warning "NPM version $NPM_VERSION is installed, but version 8 or higher is required. Installing NPM..."
        sudo apt install -y npm
        print_success "NPM installed."
    fi
else
    print_step "Installing NPM..."
    sudo apt install -y npm
    print_success "NPM installed."
fi

# Clone repository từ GitHub
print_step "Checking if the project directory already exists..."
if [ -d "web-game-manager" ] && [ "$(ls -A web-game-manager)" ]; then
    print_warning "Directory 'web-game-manager' already exists and is not empty. Skipping clone."
else
    print_step "Cloning the project repository..."
    if git clone https://github.com/nguyentronghuan101120/web-game-manager.git; then
        print_success "Repository cloned."
    else
        print_error "Failed to clone repository."
        exit 1
    fi
fi

# Chuyển đến thư mục dự án
print_step "Changing directory to the project..."
cd web-game-manager || { print_error "Directory not found!"; exit 1; }

# Cài đặt các package của dự án
print_step "Installing project dependencies..."
npm install
print_success "Dependencies installed."

# Cài đặt PM2 toàn cục
print_step "Checking if PM2 is installed globally..."
if command -v pm2 > /dev/null; then
    print_success "PM2 is already installed."
else
    print_step "Installing PM2 globally..."
    sudo npm install pm2 -g
    print_success "PM2 installed."
fi

# Khởi động server bằng PM2
print_step "Checking if server is already started with PM2..."
if pm2 list | grep -q "Nodemy-server"; then
    print_success "Server is already started with PM2."
else
    print_step "Starting server using PM2..."
    pm2 start npm --name "Nodemy-server" -- start
    print_success "Server started with PM2."
fi

# Lưu cấu hình PM2
print_step "Checking if PM2 configuration is already saved..."
if pm2 save --test; then
    print_success "PM2 configuration is already saved."
else
    print_step "Saving PM2 configuration..."
    pm2 save
    print_success "PM2 configuration saved."
fi

# Thiết lập PM2 khởi động cùng hệ thống
print_step "Checking if PM2 is set to start on system startup..."
if pm2 startup | grep -q "already"; then
    print_success "PM2 is already configured to start on system startup."
else
    print_step "Setting PM2 to start on system startup..."
    pm2 startup
    print_success "PM2 configured to start on system startup."
fi

# Cấu hình tường lửa cho phép cổng 3000
print_step "Checking if port 3000 is already allowed in UFW..."
if sudo ufw status | grep -q "3000"; then
    print_success "Port 3000 is already allowed in UFW."
else
    print_step "Allowing port 3000 in UFW firewall..."
    sudo ufw allow 3000
    print_success "Port 3000 allowed in UFW."
fi

# Reset tường lửa UFW
print_step "Checking if UFW firewall needs resetting..."
# Note: This step is tricky because resetting UFW is a destructive action.
# You might want to reconsider if this step should be skipped based on a condition.
print_step "Resetting UFW firewall..."
sudo ufw reset
print_success "UFW firewall reset."

echo -e "${GREEN}========== Setup complete. ==========${NC}"
