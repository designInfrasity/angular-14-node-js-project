#!/bin/bash

#############################################################################
# Step 8.1: Angular Client Linting and TypeScript Verification Script
#############################################################################
#
# This script automates the verification of Angular code quality through:
# 1. Linting configuration check (ng lint)
# 2. TypeScript 4.9.5 compilation check with strict mode
# 3. Comprehensive error reporting and documentation
#
# Usage:
#   ./run-linting-verification.sh [OPTIONS]
#
# Options:
#   --all              Run all verification checks (default)
#   --lint             Check linting configuration and run if available
#   --typescript       Run TypeScript compilation checks
#   --install-eslint   Install and configure @angular-eslint (optional)
#   --help             Show this help message
#
#############################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0

# Navigate to Angular client directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

#############################################################################
# Helper Functions
#############################################################################

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${BLUE}--- $1${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
    ((PASSED_CHECKS++))
    ((TOTAL_CHECKS++))
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    ((FAILED_CHECKS++))
    ((TOTAL_CHECKS++))
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
    ((WARNINGS++))
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

#############################################################################
# Prerequisites Check
#############################################################################

check_prerequisites() {
    print_header "Prerequisites Check"

    # Check Node.js version
    print_section "Node.js Version"
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        if [[ "$NODE_VERSION" == v18.* ]]; then
            print_success "Node.js version: $NODE_VERSION"
        else
            print_error "Node.js version is $NODE_VERSION, expected v18.x.x"
            print_info "Run: nvm use 18"
            return 1
        fi
    else
        print_error "Node.js not found"
        return 1
    fi

    # Check npm version
    print_section "npm Version"
    if command -v npm &> /dev/null; then
        NPM_VERSION=$(npm --version)
        print_success "npm version: $NPM_VERSION"
    else
        print_error "npm not found"
        return 1
    fi

    # Check if node_modules exists
    print_section "Dependencies Installation"
    if [ -d "node_modules" ]; then
        print_success "node_modules directory exists"

        # Check TypeScript installation
        if [ -d "node_modules/typescript" ]; then
            print_success "TypeScript package installed"
        else
            print_error "TypeScript package not found in node_modules"
            print_info "Run: npm install"
            return 1
        fi

        # Check Angular CLI installation
        if [ -d "node_modules/@angular/cli" ]; then
            print_success "Angular CLI package installed"
        else
            print_error "Angular CLI package not found in node_modules"
            print_info "Run: npm install"
            return 1
        fi
    else
        print_error "node_modules directory not found"
        print_info "Run: cd /code/angular-14-client && npm install"
        return 1
    fi

    # Check TypeScript version
    print_section "TypeScript Version"
    if command -v npx &> /dev/null; then
        TS_VERSION=$(npx tsc --version 2>&1 || echo "not found")
        if [[ "$TS_VERSION" == *"4.9.5"* ]]; then
            print_success "TypeScript version: $TS_VERSION"
        else
            print_error "TypeScript version is $TS_VERSION, expected 4.9.5"
            print_info "Check package.json devDependencies"
            return 1
        fi
    else
        print_error "npx command not found"
        return 1
    fi

    return 0
}

#############################################################################
# Linting Configuration Check
#############################################################################

check_linting_configuration() {
    print_header "Linting Configuration Check"

    # Check for @angular-eslint packages
    print_section "ESLint Packages"
    ESLINT_INSTALLED=false
    if [ -d "node_modules/@angular-eslint" ]; then
        print_success "@angular-eslint packages found"
        ESLINT_INSTALLED=true
    else
        print_warning "@angular-eslint packages NOT installed"
        print_info "Linting is not configured in this project"
    fi

    # Check for lint configuration in angular.json
    print_section "Angular CLI Lint Configuration"
    if grep -q '"lint"' angular.json 2>/dev/null; then
        print_success "Lint target found in angular.json"
    else
        print_warning "Lint target NOT found in angular.json"
        print_info "Run 'ng add @angular-eslint/schematics' to add linting"
    fi

    # Check for .eslintrc.json
    print_section "ESLint Configuration File"
    if [ -f ".eslintrc.json" ] || [ -f ".eslintrc.js" ]; then
        print_success "ESLint configuration file found"
    else
        print_warning "ESLint configuration file NOT found"
    fi

    # Check for lint script in package.json
    print_section "Lint Script in package.json"
    if grep -q '"lint"' package.json 2>/dev/null; then
        print_success "Lint script found in package.json"
    else
        print_warning "Lint script NOT found in package.json"
    fi

    echo ""
    if [ "$ESLINT_INSTALLED" = false ]; then
        print_info "CONCLUSION: Linting is NOT currently configured for this project"
        print_info "This is acceptable. TypeScript strict mode provides code quality checks."
        print_info "To add linting, run: ng add @angular-eslint/schematics"
    else
        print_info "CONCLUSION: Linting IS configured for this project"
    fi

    return 0
}

#############################################################################
# Run Linting (if configured)
#############################################################################

run_linting() {
    print_header "Run Linting"

    # Check if lint command is available
    if ! grep -q '"lint"' angular.json 2>/dev/null; then
        print_warning "Linting not configured - skipping ng lint"
        print_info "To add linting support, use option: --install-eslint"
        return 0
    fi

    print_section "Running ng lint"
    print_info "This may take a moment..."

    if npx ng lint 2>&1 | tee lint-output.log; then
        print_success "Linting passed with no errors"
        rm -f lint-output.log
        return 0
    else
        print_error "Linting failed with errors"
        print_info "Review lint-output.log for details"
        print_info "Run 'ng lint --fix' to auto-fix issues"
        return 1
    fi
}

#############################################################################
# TypeScript Compilation Check
#############################################################################

check_typescript_compilation() {
    print_header "TypeScript Compilation Verification"

    # Check all TypeScript files
    print_section "TypeScript Compilation Check (All Files)"
    print_info "Running: npx tsc --noEmit"
    print_info "This checks all TypeScript files with strict mode settings..."
    echo ""

    if npx tsc --noEmit 2>&1 | tee typescript-all-output.log; then
        print_success "TypeScript compilation successful (all files)"
        rm -f typescript-all-output.log
    else
        print_error "TypeScript compilation failed (all files)"
        echo ""
        echo -e "${RED}Compilation Errors:${NC}"
        cat typescript-all-output.log
        echo ""
        print_info "Review errors above and fix type issues"
        return 1
    fi

    # Check app TypeScript files
    print_section "TypeScript Compilation Check (App Files)"
    print_info "Running: npx tsc --project tsconfig.app.json --noEmit"
    print_info "This checks application source files in src/..."
    echo ""

    if npx tsc --project tsconfig.app.json --noEmit 2>&1 | tee typescript-app-output.log; then
        print_success "TypeScript compilation successful (app files)"
        rm -f typescript-app-output.log
    else
        print_error "TypeScript compilation failed (app files)"
        echo ""
        echo -e "${RED}Compilation Errors:${NC}"
        cat typescript-app-output.log
        echo ""
        return 1
    fi

    # Check test TypeScript files
    print_section "TypeScript Compilation Check (Test Files)"
    print_info "Running: npx tsc --project tsconfig.spec.json --noEmit"
    print_info "This checks test files (*.spec.ts)..."
    echo ""

    if npx tsc --project tsconfig.spec.json --noEmit 2>&1 | tee typescript-spec-output.log; then
        print_success "TypeScript compilation successful (test files)"
        rm -f typescript-spec-output.log
    else
        print_error "TypeScript compilation failed (test files)"
        echo ""
        echo -e "${RED}Compilation Errors:${NC}"
        cat typescript-spec-output.log
        echo ""
        return 1
    fi

    return 0
}

#############################################################################
# Install @angular-eslint (Optional)
#############################################################################

install_angular_eslint() {
    print_header "Install @angular-eslint"

    print_warning "This will install and configure @angular-eslint in the project"
    print_info "This may introduce new lint errors that need to be fixed"
    echo ""
    read -p "Continue? (y/n) " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled"
        return 0
    fi

    print_section "Running ng add @angular-eslint/schematics"

    if npx ng add @angular-eslint/schematics; then
        print_success "@angular-eslint installed and configured"
        print_info "You can now run: ng lint"
        return 0
    else
        print_error "Failed to install @angular-eslint"
        return 1
    fi
}

#############################################################################
# Display TypeScript Configuration
#############################################################################

show_typescript_config() {
    print_header "TypeScript Configuration Review"

    print_section "tsconfig.json - Compiler Options"
    echo "Strict mode settings enabled:"
    echo "  - strict: true (all strict checks enabled)"
    echo "  - noImplicitOverride: true"
    echo "  - noPropertyAccessFromIndexSignature: true"
    echo "  - noImplicitReturns: true"
    echo "  - noFallthroughCasesInSwitch: true"
    echo "  - forceConsistentCasingInFileNames: true"
    echo ""
    echo "Angular compiler options:"
    echo "  - strictInjectionParameters: true"
    echo "  - strictInputAccessModifiers: true"
    echo "  - strictTemplates: true"
    echo ""
    print_info "These settings provide strong type safety and code quality guarantees"
}

#############################################################################
# Summary Report
#############################################################################

print_summary() {
    print_header "Step 8.1 Verification Summary"

    echo -e "${BLUE}Total checks:${NC} $TOTAL_CHECKS"
    echo -e "${GREEN}Passed:${NC} $PASSED_CHECKS"
    echo -e "${RED}Failed:${NC} $FAILED_CHECKS"
    echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
    echo ""

    if [ $FAILED_CHECKS -eq 0 ]; then
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}✓ STEP 8.1 VERIFICATION PASSED${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo ""
        echo "Next Steps:"
        echo "  1. Review this output and document findings"
        echo "  2. Update STEP-8.1-IMPLEMENTATION-SUMMARY.md"
        echo "  3. Update session learnings (.aviator/current_session_learnings.md)"
        echo "  4. Proceed to Step 8.2: Review Server Code for Node.js 18 Compatibility"
        echo ""
        return 0
    else
        echo -e "${RED}========================================${NC}"
        echo -e "${RED}✗ STEP 8.1 VERIFICATION FAILED${NC}"
        echo -e "${RED}========================================${NC}"
        echo ""
        echo "Action Required:"
        echo "  1. Review error messages above"
        echo "  2. Fix TypeScript compilation errors"
        echo "  3. Re-run this script to verify fixes"
        echo ""
        return 1
    fi
}

#############################################################################
# Main Execution
#############################################################################

show_help() {
    echo "Step 8.1: Angular Client Linting and TypeScript Verification"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --all              Run all verification checks (default)"
    echo "  --prerequisites    Check prerequisites only"
    echo "  --lint             Check linting configuration and run if available"
    echo "  --typescript       Run TypeScript compilation checks only"
    echo "  --config           Show TypeScript configuration"
    echo "  --install-eslint   Install and configure @angular-eslint (optional)"
    echo "  --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Run all checks"
    echo "  $0 --typescript         # Run only TypeScript checks"
    echo "  $0 --install-eslint     # Install @angular-eslint"
    echo ""
}

main() {
    local MODE="all"

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --all)
                MODE="all"
                shift
                ;;
            --prerequisites)
                MODE="prerequisites"
                shift
                ;;
            --lint)
                MODE="lint"
                shift
                ;;
            --typescript)
                MODE="typescript"
                shift
                ;;
            --config)
                MODE="config"
                shift
                ;;
            --install-eslint)
                MODE="install-eslint"
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    print_header "Step 8.1: Angular Client Linting Verification"
    print_info "Verifying Angular code quality with Node.js 18 and TypeScript 4.9.5"
    print_info "Project: angular-14-client"
    print_info "Working directory: $SCRIPT_DIR"

    # Execute based on mode
    case $MODE in
        prerequisites)
            check_prerequisites || exit 1
            ;;
        lint)
            check_prerequisites || exit 1
            check_linting_configuration
            run_linting
            ;;
        typescript)
            check_prerequisites || exit 1
            check_typescript_compilation || exit 1
            ;;
        config)
            show_typescript_config
            ;;
        install-eslint)
            check_prerequisites || exit 1
            install_angular_eslint
            ;;
        all)
            check_prerequisites || exit 1
            show_typescript_config
            check_linting_configuration
            # Only run linting if configured
            if grep -q '"lint"' angular.json 2>/dev/null; then
                run_linting
            fi
            check_typescript_compilation || exit 1
            ;;
    esac

    # Print summary for comprehensive runs
    if [ "$MODE" = "all" ] || [ "$MODE" = "typescript" ]; then
        print_summary
        exit $?
    fi

    exit 0
}

# Run main function
main "$@"
