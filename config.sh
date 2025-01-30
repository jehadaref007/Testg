#!/bin/bash

# RootRecon - أداة متقدمة للاستكشاف والتحليل الأمني
# الإصدار 1.0

# رموز الألوان لتحسين قراءة المخرجات
declare -r AZRAQ='\033[94m'      # أزرق للمعلومات العامة
declare -r AHMAR='\033[91m'      # أحمر للأخطاء والتحذيرات
declare -r AKHDAR='\033[92m'     # أخضر للعمليات الناجحة
declare -r BURTUQALI='\033[93m'  # برتقالي للتنبيهات
declare -r RESET='\e[0m'         # إعادة تعيين اللون
declare -r BOLD='\e[1m'          # نص عريض
declare -r UNDERLINE='\e[4m'     # نص تحته خط

# المتغيرات العامة للتكوين
declare -r VERSION="1.0"         # إصدار الأداة
declare BROWSER="firefox"        # المتصفح الافتراضي
declare DELAY=5                  # التأخير بين العمليات
declare QUIET_MODE=false         # وضع الهدوء
declare VERBOSE=true             # الوضع التفصيلي
declare REPORT_DIR="تقارير_الاستكشاف"  # مجلد التقارير
declare MAX_THREADS=5            # الحد الأقصى للخيوط المتزامنة

# قائمة التبعيات المطلوبة
CORE_DEPENDENCIES=("curl" "jq" "whois" "dig")
OPTIONAL_DEPENDENCIES=("nmap" "pandoc" "wkhtmltopdf" "searchsploit")

# تكوين التسجيل
LOG_FILE="${REPORT_DIR}/سجل_RootRecon_$(date +%Y%m%d_%H%M%S).log"

# إنشاء مجلد التقارير إذا لم يكن موجودًا
mkdir -p "$REPORT_DIR"

# دالة التسجيل
سجل_الرسالة() {
    local مستوى="$1"
    local رسالة="$2"
    local الطابع_الزمني=$(date "+%Y-%m-%d %H:%M:%S")
    
    case "$مستوى" in
        "معلومات")
            echo -e "${AZRAQ}[معلومات] ${الطابع_الزمني}: ${رسالة}${RESET}" | tee -a "$LOG_FILE"
            ;;
        "تحذير")
            echo -e "${BURTUQALI}[تحذير] ${الطابع_الزمني}: ${رسالة}${RESET}" | tee -a "$LOG_FILE"
            ;;
        "خطأ")
            echo -e "${AHMAR}[خطأ] ${الطابع_الزمني}: ${رسالة}${RESET}" | tee -a "$LOG_FILE"
            ;;
        "نجاح")
            echo -e "${AKHDAR}[نجاح] ${الطابع_الزمني}: ${رسالة}${RESET}" | tee -a "$LOG_FILE"
            ;;
        *)
            echo -e "${رسالة}" | tee -a "$LOG_FILE"
            ;;
    esac
}

# دالة التحقق من التبعيات
التحقق_من_التبعيات() {
    سجل_الرسالة "معلومات" "جارٍ التحقق من التبعيات النظامية..."
    
    # التحقق من التبعيات الأساسية
    for dep in "${CORE_DEPENDENCIES[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            سجل_الرسالة "خطأ" "لم يتم العثور على $dep. يرجى تثبيته أولاً."
            return 1
        else
            سجل_الرسالة "نجاح" "تم العثور على $dep"
        fi
    done
    
    # التحقق من التبعيات الاختيارية
    سجل_الرسالة "معلومات" "التحقق من التبعيات الاختيارية..."
    for dep in "${OPTIONAL_DEPENDENCIES[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            سجل_الرسالة "تحذير" "لم يتم العثور على $dep. بعض الميزات المتقدمة ستكون محدودة."
        else
            سجل_الرسالة "نجاح" "تم العثور على $dep"
        fi
    done
}

# تشغيل التحقق من التبعيات
التحقق_من_التبعيات