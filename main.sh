#!/bin/bash

# RootRecon - Advanced Security and Reconnaissance Tool
# استيراد الوحدات والإعدادات
source "config.sh"
source "modules/domain_info.sh"
source "modules/security_headers.sh"
source "modules/vulnerability_scan.sh"
source "modules/port_scan.sh"
source "modules/cve_scan.sh"
source "modules/generate_report.sh"

# دالة عرض المساعدة
usage() {
    echo "RootRecon v${VERSION} - Advanced Security and Reconnaissance Tool"
    echo "Usage: $0 [options] <target>"
    echo ""
    echo "Options:"
    echo "  -d, --domain     Target domain or IP to scan"
    echo "  -q, --quiet      Enable quiet mode (minimal output)"
    echo "  -v, --verbose    Enable verbose mode (detailed output)"
    echo "  -o, --output     Specify custom output directory"
    echo "  -h, --help       Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -d example.com"
    echo "  $0 --domain example.com --quiet"
    echo "  $0 -d 192.168.1.1 -o /custom/report/path"
}

# معالجة الأوامر والخيارات
parse_arguments() {
    local ARGS
    ARGS=$(getopt -o d:qvo:h --long domain:,quiet,verbose,output:,help -n "$0" -- "$@")
    
    if [ $? -ne 0 ]; then
        usage
        exit 1
    fi
    
    eval set -- "$ARGS"
    
    while true; do
        case "$1" in
            -d|--domain)
                TARGET="$2"
                shift 2
                ;;
            -q|--quiet)
                QUIET_MODE=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -o|--output)
                REPORT_DIR="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            --)
                shift
                break
                ;;
            *)
                log_message "ERROR" "Invalid argument: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# الدالة الرئيسية للمسح والتحليل
main_reconnaissance() {
    local target="$1"
    
    # التحقق من وجود الهدف
    if [[ -z "$target" ]]; then
        log_message "ERROR" "No target specified. Use -h for help."
        exit 1
    fi
    
    # التحقق من التبعيات قبل البدء
    check_dependencies || exit 1
    
    # تحديث قاعدة بيانات الثغرات
    update_vulnerability_database
    
    # تنفيذ الوحدات المختلفة
    log_message "INFO" "Starting comprehensive reconnaissance for target: $target"
    
    # 1. استخراج معلومات النطاق
    استخراج_معلومات_النطاق "$target"
    
    # 2. تحليل رؤوس الأمان
    analyze_security_headers "$target"
    
    # 3. فحص نقاط الضعف
    scan_vulnerabilities "$target"
    
    # 4. مسح المنافذ
    advanced_port_scan "$target"
    
    # 5. التحقق من ثغرات CVE
    check_cve_vulnerabilities "$target"
    
    # 6. إنشاء التقرير النهائي
    generate_html_report "$target"
    
    log_message "SUCCESS" "Reconnaissance completed successfully"
}

# نقطة الدخول الرئيسية للسكربت
main() {
    # معالجة الأوامر
    parse_arguments "$@"
    
    # بدء المسح الرئيسي
    main_reconnaissance "$TARGET"
}

# تشغيل الدالة الرئيسية
main "$@"