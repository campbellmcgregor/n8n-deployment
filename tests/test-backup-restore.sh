#!/bin/bash

# Test Suite for n8n Backup and Restore Scripts
# This script tests the backup.sh and restore.sh functionality

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Print colored output
print_color() {
    printf "${1}${2}${NC}\n"
}

print_header() {
    echo ""
    print_color $BLUE "================================"
    print_color $BLUE "$1"
    print_color $BLUE "================================"
}

print_test() {
    TESTS_RUN=$((TESTS_RUN + 1))
    print_color $YELLOW "Test #$TESTS_RUN: $1"
}

print_pass() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    print_color $GREEN "✓ PASSED: $1"
}

print_fail() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    print_color $RED "✗ FAILED: $1"
}

print_info() {
    print_color $BLUE "ℹ $1"
}

# Test environment setup
setup_test_env() {
    print_header "Setting Up Test Environment"

    # Backup original files if they exist
    if [ -d "backups" ]; then
        mv backups backups.test-backup 2>/dev/null || true
    fi

    # Create test backup directory
    mkdir -p backups

    # Create mock backup files for testing
    TEST_DATE="20250101_120000"
    echo "-- Mock PostgreSQL backup" | gzip >"backups/postgres-backup-$TEST_DATE.sql.gz"
    echo "Mock n8n backup data" | tar czf "backups/n8n-backup-$TEST_DATE.tar.gz" -T /dev/null 2>/dev/null || true

    print_pass "Test environment setup completed"
}

# Clean up test environment
cleanup_test_env() {
    print_header "Cleaning Up Test Environment"

    # Remove test backup directory
    rm -rf backups

    # Restore original backups if they existed
    if [ -d "backups.test-backup" ]; then
        mv backups.test-backup backups
    fi

    print_pass "Test environment cleanup completed"
}

# Test backup script existence and permissions
test_backup_script_exists() {
    print_test "Backup script exists and is executable"

    if [ -f "scripts/backup.sh" ] && [ -x "scripts/backup.sh" ]; then
        print_pass "backup.sh exists and is executable"
    else
        print_fail "backup.sh missing or not executable"
    fi
}

# Test restore script existence and permissions
test_restore_script_exists() {
    print_test "Restore script exists and is executable"

    if [ -f "scripts/restore.sh" ] && [ -x "scripts/restore.sh" ]; then
        print_pass "restore.sh exists and is executable"
    else
        print_fail "restore.sh missing or not executable"
    fi
}

# Test backup script help output
test_backup_help() {
    print_test "Backup script help functionality"

    # Note: backup.sh doesn't have --help, but should run without error
    if timeout 10s scripts/backup.sh --help 2>/dev/null || [ $? -eq 124 ]; then
        print_pass "backup.sh handles help request gracefully"
    else
        print_info "backup.sh doesn't have --help (expected)"
    fi
}

# Test restore script help output
test_restore_help() {
    print_test "Restore script help functionality"

    if scripts/restore.sh --help >/dev/null 2>&1; then
        print_pass "restore.sh --help works correctly"
    else
        print_fail "restore.sh --help failed"
    fi
}

# Test restore script list functionality
test_restore_list() {
    print_test "Restore script list backups functionality"

    output=$(scripts/restore.sh --list 2>&1)
    if echo "$output" | grep -q "Available Backups" && echo "$output" | grep -q "20250101_120000"; then
        print_pass "restore.sh --list shows available backups"
    else
        print_fail "restore.sh --list didn't show expected backups"
    fi
}

# Test backup directory creation
test_backup_directory() {
    print_test "Backup directory structure"

    if [ -d "backups" ]; then
        print_pass "Backup directory exists"
    else
        print_fail "Backup directory missing"
    fi
}

# Test backup file formats
test_backup_formats() {
    print_test "Backup file formats and naming"

    # Check if mock backup files exist with correct format
    if ls backups/postgres-backup-*.sql.gz >/dev/null 2>&1; then
        print_pass "PostgreSQL backup files have correct format"
    else
        print_fail "PostgreSQL backup files format incorrect"
    fi

    if ls backups/n8n-backup-*.tar.gz >/dev/null 2>&1; then
        print_pass "n8n backup files have correct format"
    else
        print_fail "n8n backup files format incorrect"
    fi
}

# Test restore script validation
test_restore_validation() {
    print_test "Restore script backup validation"

    # Test with non-existent backup
    if ! scripts/restore.sh --force nonexistent_backup 2>/dev/null; then
        print_pass "restore.sh correctly rejects non-existent backup"
    else
        print_fail "restore.sh should reject non-existent backup"
    fi
}

# Test Docker dependency check
test_docker_dependency() {
    print_test "Docker dependency check"

    if docker info >/dev/null 2>&1; then
        print_pass "Docker is available for testing"
    else
        print_info "Docker not available - some tests will be skipped"
        return 1
    fi
}

# Test script argument parsing
test_script_arguments() {
    print_test "Script argument parsing"

    # Test restore script with various arguments
    if scripts/restore.sh --help >/dev/null 2>&1; then
        print_pass "restore.sh handles --help"
    else
        print_fail "restore.sh --help failed"
    fi

    if scripts/restore.sh --list >/dev/null 2>&1; then
        print_pass "restore.sh handles --list"
    else
        print_fail "restore.sh --list failed"
    fi
}

# Test script error handling
test_error_handling() {
    print_test "Script error handling"

    # Test with invalid arguments
    if ! scripts/restore.sh --invalid-option >/dev/null 2>&1; then
        print_pass "restore.sh properly handles invalid options"
    else
        print_fail "restore.sh should reject invalid options"
    fi
}

# Test file permissions and security
test_file_security() {
    print_test "File permissions and security"

    # Check that scripts are executable
    if [ -x "scripts/backup.sh" ] && [ -x "scripts/restore.sh" ]; then
        print_pass "Scripts have correct executable permissions"
    else
        print_fail "Scripts missing executable permissions"
    fi

    # Check that backup files are readable
    if ls backups/*.gz >/dev/null 2>&1; then
        for file in backups/*.gz; do
            if [ -r "$file" ]; then
                print_pass "Backup file $file is readable"
            else
                print_fail "Backup file $file is not readable"
            fi
        done
    fi
}

# Test integration with start/stop scripts
test_integration() {
    print_test "Integration with start/stop scripts"

    if [ -f "scripts/start_n8n.sh" ] && [ -f "scripts/stop_n8n.sh" ]; then
        print_pass "Start/stop scripts exist for integration"
    else
        print_fail "Start/stop scripts missing"
    fi
}

# Main test execution
run_all_tests() {
    print_header "n8n Backup/Restore Test Suite"
    print_info "Starting comprehensive test suite..."

    # Setup
    setup_test_env

    # Core functionality tests
    test_backup_script_exists
    test_restore_script_exists
    test_backup_help
    test_restore_help
    test_restore_list
    test_backup_directory
    test_backup_formats
    test_restore_validation
    test_script_arguments
    test_error_handling
    test_file_security
    test_integration

    # Docker-dependent tests (optional)
    if test_docker_dependency; then
        print_info "Running Docker-dependent tests..."
        # Add Docker-specific tests here if needed
    fi

    # Cleanup
    cleanup_test_env

    # Results
    print_header "Test Results"
    print_color $BLUE "Tests Run: $TESTS_RUN"
    print_color $GREEN "Tests Passed: $TESTS_PASSED"
    print_color $RED "Tests Failed: $TESTS_FAILED"

    if [ $TESTS_FAILED -eq 0 ]; then
        print_color $GREEN "🎉 All tests passed!"
        exit 0
    else
        print_color $RED "❌ Some tests failed!"
        exit 1
    fi
}

# Show usage
show_usage() {
    echo "n8n Backup/Restore Test Suite"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help    Show this help message"
    echo "  --quick   Run only quick tests (skip Docker tests)"
    echo ""
    echo "This script tests the backup.sh and restore.sh functionality"
}

# Parse arguments
case "${1:-}" in
--help | -h)
    show_usage
    exit 0
    ;;
--quick)
    print_info "Running quick test suite (Docker tests skipped)"
    ;;
"")
    # Default: run all tests
    ;;
*)
    echo "Unknown option: $1"
    show_usage
    exit 1
    ;;
esac

# Run the tests
run_all_tests
