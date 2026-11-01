#!/usr/bin/env bash
# §14.9 paso 3: patrones prohibidos en código de producción (ADR-12, ADR-13, directrices 2.1(a) y 2.5.19).
set -euo pipefail
cd "$(dirname "$0")/.."

dirs=()
for dir in Packages/CalendarioKit/Sources calendariodepagos Shared TodayPaymentsWidget; do
    [[ -d "$dir" ]] && dirs+=("$dir")
done

# TestSupport solo lo usan las pruebas; no se enlaza en la app.
pattern='try!|as!|fatalError\(|print\(|@unchecked Sendable|UserDefaults\.standard|@AppStorage|URLSession|Lorem|Próximamente|Coming soon|Android'
if grep -rnE --include='*.swift' --exclude-dir=TestSupport "$pattern" "${dirs[@]}"; then
    echo "error: patrones prohibidos encontrados (ver §14.9)." >&2
    exit 1
fi
echo "Sin patrones prohibidos."
