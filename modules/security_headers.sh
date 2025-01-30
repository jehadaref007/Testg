#!/bin/bash

# استيراد الإعدادات العامة
source "../config.sh"

# دالة تحليل رؤوس الأمان
analyze_security_headers() {
    local domain="$1"
    
    # التحقق من صحة النطاق
    if [[ -z "$domain" ]]; then
        log_message "ERROR" "No domain specified for analysis"
        return 1
    fi
    
    # إنشاء مجلد للنتائج
    local results_dir="${REPORT_DIR}/security_headers_${domain}"
    mkdir -p "$results_dir"
    
    log_message "INFO" "Starting security headers analysis for domain: $domain"
    
    # استخدام curl لجلب رؤوس الأمان
    local headers_file="${results_dir}/security_headers.txt"
    
    # تحليل الرؤوس الأمنية
    curl -sI "https://$domain" > "$headers_file" 2>&1
    
    # تحليل الرؤوس وتقييم الأمان
    local security_report="${results_dir}/security_assessment.txt"
    
    {
        echo "Security Headers Analysis Report for Domain: $domain"
        echo "-----------------------------------"
        
        # التحقق من رأس Strict-Transport-Security (HSTS)
        if grep -qi "Strict-Transport-Security" "$headers_file"; then
            echo "[+] HSTS Enabled: Provides protection against redirect attacks"
        else
            echo "[-] HSTS Disabled: Vulnerable to redirect attacks"
        fi
        
        # التحقق من رأس X-Frame-Options
        if grep -qi "X-Frame-Options" "$headers_file"; then
            echo "[+] X-Frame-Options Enabled: Protection against clickjacking"
        else
            echo "[-] X-Frame-Options Disabled: Vulnerable to clickjacking"
        fi
        
        # التحقق من رأس X-XSS-Protection
        if grep -qi "X-XSS-Protection" "$headers_file"; then
            echo "[+] X-XSS-Protection Enabled: Protection against XSS attacks"
        else
            echo "[-] X-XSS-Protection Disabled: Vulnerable to XSS attacks"
        fi
        
        # التحقق من رأس Content-Security-Policy
        if grep -qi "Content-Security-Policy" "$headers_file"; then
            echo "[+] Content-Security-Policy Enabled: Restricts content sources"
        else
            echo "[-] Content-Security-Policy Disabled: Vulnerable to content injection"
        fi
        
        # التحقق من رأس Referrer-Policy
        if grep -qi "Referrer-Policy" "$headers_file"; then
            echo "[+] Referrer-Policy Enabled: Controls referrer information"
        else
            echo "[-] Referrer-Policy Disabled: Referrer information may leak"
        fi
    } > "$security_report"
    
    log_message "SUCCESS" "Completed security headers analysis"
    
    return 0
}

# تصدير الدالة للاستخدام في وحدات أخرى
export -f analyze_security_headers