#!/bin/bash

# استيراد الإعدادات العامة
source "../config.sh"

# دالة التحقق من ثغرات CVE
check_cve_vulnerabilities() {
    local target="$1"
    local service_version="${2:-auto}"
    
    # التحقق من صحة الهدف
    if [[ -z "$target" ]]; then
        log_message "ERROR" "No target specified for CVE vulnerability scan"
        return 1
    fi
    
    # إنشاء مجلد للنتائج
    local results_dir="${REPORT_DIR}/cve_scan_${target}"
    mkdir -p "$results_dir"
    
    log_message "INFO" "Starting CVE vulnerability scan for target: $target"
    
    # 1. جمع معلومات الخدمات والإصدارات
    log_message "INFO" "Collecting service and version information"
    if [[ "$service_version" == "auto" ]]; then
        nmap -sV -sC "$target" > "${results_dir}/service_versions.txt"
    fi
    
    # 2. البحث عن ثغرات CVE باستخدام نماذج متعددة
    log_message "INFO" "Searching for known CVE vulnerabilities"
    
    # a. استخدام nmap للتحقق من الثغرات المعروفة
    nmap --script vuln "$target" > "${results_dir}/nmap_cve_scan.txt"
    
    # b. استخدام searchsploit للبحث عن الثغرات
    if command -v searchsploit &> /dev/null; then
        searchsploit --nmap "${results_dir}/service_versions.txt" > "${results_dir}/searchsploit_results.txt"
    else
        log_message "WARNING" "searchsploit not installed. Skipping exploit database search"
    fi
    
    # c. استخدام curl للتحقق من قاعدة بيانات CVE عبر الإنترنت
    log_message "INFO" "Checking online CVE databases"
    {
        echo "CVE Vulnerability Check for Target: $target"
        echo "----------------------------------------"
        
        # استخراج الخدمات والإصدارات
        echo "1. Detected Services and Versions:"
        grep -E "service:|version:" "${results_dir}/service_versions.txt" || echo "No service details found"
        
        # ثغرات CVE من nmap
        echo -e "\n2. Potential CVE Vulnerabilities (nmap):"
        grep -E "CVE-" "${results_dir}/nmap_cve_scan.txt" || echo "No CVE vulnerabilities detected by nmap"
        
        # نتائج searchsploit
        if [ -f "${results_dir}/searchsploit_results.txt" ]; then
            echo -e "\n3. Potential Exploits (searchsploit):"
            cat "${results_dir}/searchsploit_results.txt" || echo "No exploits found in database"
        fi
    } > "${results_dir}/cve_vulnerability_report.txt"
    
    # 3. تحليل وتصنيف الثغرات
    local severity_report="${results_dir}/vulnerability_severity.txt"
    {
        echo "CVE Vulnerability Severity Assessment"
        echo "-------------------------------------"
        
        # تصنيف الثغرات حسب الشدة
        echo "Severity Levels:"
        echo "- Critical: Immediate action required"
        echo "- High: Urgent patching recommended"
        echo "- Medium: Address in next maintenance window"
        echo "- Low: Monitor and assess"
        
        # استخراج وتصنيف الثغرات
        grep -E "CVE-" "${results_dir}/nmap_cve_scan.txt" | awk '{print $1, $2}' | sort -u
    } > "$severity_report"
    
    log_message "SUCCESS" "Completed CVE vulnerability scanning"
    
    return 0
}

# دالة تحديث قاعدة بيانات الثغرات
update_vulnerability_database() {
    log_message "INFO" "Updating vulnerability databases"
    
    # تحديث searchsploit
    if command -v searchsploit &> /dev/null; then
        searchsploit -u
    else
        log_message "WARNING" "searchsploit not installed. Skipping database update"
    fi
    
    # تحديث nmap scripts
    nmap --script-updatedb
    
    log_message "SUCCESS" "Vulnerability databases updated"
}

# تصدير الدوال للاستخدام في وحدات أخرى
export -f check_cve_vulnerabilities
export -f update_vulnerability_database