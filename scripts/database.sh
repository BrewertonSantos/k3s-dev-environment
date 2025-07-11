#!/bin/bash

# Database Services Management Script
# This script provides easy access to all database component scripts

show_help() {
    echo "🗄️  DATABASE SERVICES MANAGEMENT"
    echo "================================"
    echo ""
    echo "Usage: $0 [component] [action]"
    echo ""
    echo "📊 COMPONENTS:"
    echo "  mysql      - MySQL database services"
    echo "  cloudbeaver - CloudBeaver database management UI"
    echo "  postgres   - PostgreSQL database services"
    echo ""
    echo "🔧 ACTIONS:"
    echo "  deploy     - Deploy the component"
    echo "  cleanup    - Remove the component"
    echo "  status     - Check component status"
    echo "  configure  - Configure connections (cloudbeaver only)"
    echo "  fix        - Fix privileges (mysql only)"
    echo ""
    echo "📋 EXAMPLES:"
    echo "  $0 mysql deploy           # Deploy MySQL"
    echo "  $0 cloudbeaver deploy     # Deploy CloudBeaver"
    echo "  $0 mysql cleanup          # Remove MySQL"
    echo "  $0 mysql fix              # Fix MySQL privileges"
    echo "  $0 cloudbeaver configure  # Configure CloudBeaver connections"
    echo ""
    echo "🗂️  DIRECT SCRIPT ACCESS:"
    echo "  MySQL scripts:      ./scripts/mysql/"
    echo "  CloudBeaver scripts: ./scripts/cloudbeaver/"
    echo "  PostgreSQL scripts:  ./scripts/postgres/"
    echo ""
    echo "📁 AVAILABLE SCRIPTS BY COMPONENT:"
    echo ""
    
    if [ -d "./scripts/mysql" ]; then
        echo "📊 MySQL Scripts:"
        ls -1 ./scripts/mysql/*.sh 2>/dev/null | sed 's|./scripts/mysql/|  - |g' | sed 's|.sh||g'
        echo ""
    fi
    
    if [ -d "./scripts/cloudbeaver" ]; then
        echo "🌐 CloudBeaver Scripts:"
        ls -1 ./scripts/cloudbeaver/*.sh 2>/dev/null | sed 's|./scripts/cloudbeaver/|  - |g' | sed 's|.sh||g'
        echo ""
    fi
    
    if [ -d "./scripts/postgres" ]; then
        echo "🐘 PostgreSQL Scripts:"
        ls -1 ./scripts/postgres/*.sh 2>/dev/null | sed 's|./scripts/postgres/|  - |g' | sed 's|.sh||g'
        echo ""
    fi
}

# Function to execute component scripts
execute_script() {
    local component=$1
    local action=$2
    local script_path=""
    
    case $component in
        mysql)
            case $action in
                deploy)   script_path="./scripts/mysql/deploy-mysql.sh" ;;
                cleanup)  script_path="./scripts/mysql/cleanup-mysql.sh" ;;
                status)   script_path="./scripts/mysql/check-mysql-status.sh" ;;
                fix)      script_path="./scripts/mysql/fix-mysql-privileges.sh" ;;
                *)        echo "❌ Unknown MySQL action: $action"; return 1 ;;
            esac
            ;;
        cloudbeaver)
            case $action in
                deploy)    script_path="./scripts/cloudbeaver/deploy-cloudbeaver.sh" ;;
                cleanup)   script_path="./scripts/cloudbeaver/cleanup-cloudbeaver.sh" ;;
                configure) script_path="./scripts/cloudbeaver/configure-cloudbeaver-connections.sh" ;;
                *)         echo "❌ Unknown CloudBeaver action: $action"; return 1 ;;
            esac
            ;;
        postgres)
            echo "ℹ️  PostgreSQL is deployed by default in this environment"
            echo "🔧 Use standard kubectl commands to manage PostgreSQL:"
            echo "   kubectl get pods -n database"
            echo "   kubectl logs -n database deployment/postgres"
            return 0
            ;;
        *)
            echo "❌ Unknown component: $component"
            show_help
            return 1
            ;;
    esac
    
    if [ -f "$script_path" ]; then
        echo "🚀 Executing: $script_path"
        echo "================================"
        bash "$script_path"
    else
        echo "❌ Script not found: $script_path"
        return 1
    fi
}

# Main script logic
case $# in
    0)
        show_help
        ;;
    1)
        if [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
            show_help
        else
            echo "❌ Missing action parameter"
            echo ""
            show_help
        fi
        ;;
    2)
        execute_script "$1" "$2"
        ;;
    *)
        echo "❌ Too many parameters"
        echo ""
        show_help
        ;;
esac
