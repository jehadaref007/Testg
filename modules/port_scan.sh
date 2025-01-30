#!/bin/bash

# استيراد الإعدادات العامة
source "../config.sh"

# دالة المسح المتقدم للمنافذ
advanced_port_scan() {
    local target="$1"
    local scan_type="${2:-comprehensive}"
    
    # التحقق من صحة الهدف
    if [[ -z "$target" ]]; then
        log_message "ERROR" "No target specified for port scanning"
        return 1
    fi
    
    # إنشاء مجلد للنتائج
    local results_dir="${REPORT_DIR}/port_scan_${target}"
    mkdir -p "$results_dir"
    
    log_message "INFO" "Starting advanced port scan for target: $target"
    
    # 1. المسح الأساسي للمنافذ الشائعة
    log_message "INFO" "Performing basic port scan"
    nmap -sS -sV -O "$target" > "${results_dir}/basic_scan.txt"
    
    # 2. المسح الشامل لجميع المنافذ
    if [[ "$scan_type" == "comprehensive" ]]; then
        log_message "INFO" "Performing comprehensive port scan"
        nmap -sS -sV -p- -T4 "$target" > "${results_dir}/comprehensive_scan.txt"
    fi
    
    # 3. مسح الثغرات والخدمات
    log_message "INFO" "Scanning for service vulnerabilities"
    nmap -sV --script vuln "$target" > "${results_dir}/service_vulnerabilities.txt"
    
    # 4. إنشاء تقرير مفصل
    local port_report="${results_dir}/port_scan_report.txt"
    {
        echo "Port Scanning Report for Target: $target"
        echo "----------------------------------------"
        
        # ملخص المنافذ المفتوحة
        echo "1. Open Ports Summary:"
        grep "open" "${results_dir}/basic_scan.txt" | grep -E "tcp|udp" || echo "No open ports found"
        
        # تفاصيل الخدمات
        echo -e "\n2. Running Services:"
        grep "service:" "${results_dir}/basic_scan.txt" || echo "No service details available"
        
        # نظام التشغيل
        echo -e "\n3. Operating System Detection:"
        grep "OS details:" "${results_dir}/basic_scan.txt" || echo "OS detection inconclusive"
        
        # الثغرات المحتملة
        echo -e "\n4. Potential Vulnerabilities:"
        grep -E "VULNERABLE|CVE" "${results_dir}/service_vulnerabilities.txt" || echo "No critical vulnerabilities detected"
    } > "$port_report"
    
    log_message "SUCCESS" "Completed advanced port scanning"
    
    return 0
}

# دالة مسح المنافذ السريع
quick_port_scan() {
    local target="$1"
    
    # التحقق من صحة الهدف
    if [[ -z "$target" ]]; then
        log_message "ERROR" "No target specified for quick port scan"
        return 1
    fi
    
    # إنشاء مجلد للنتائج
    local results_dir="${REPORT_DIR}/quick_port_scan_${target}"
    mkdir -p "$results_dir"
    
    log_message "INFO" "Starting quick port scan for target: $target"
    
    # مسح سريع للمنافذ الشائعة
    nmap -sS -sV -F "$target" > "${results_dir}/quick_scan.txt"
    
    log_message "SUCCESS" "Completed quick port scanning"
    
    return 0
}

# تصدير الدوال للاستخدام في وحدات أخرى
export -f advanced_port_scan
export -f quick_port_scan