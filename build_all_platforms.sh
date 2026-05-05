#!/bin/zsh

# ==============================================================================
# SCRIPT DE BUILD MULTIPLATAFORMA - VideoDuplicateFinder
# Suporta: macOS (Intel/ARM), Windows (x64), Linux (x64) e Web
# ==============================================================================

# Configurações de Nome e Projetos
APP_NAME="VideoDuplicateFinder"
EXEC_NAME="VDF.GUI" 
PROJECT_GUI="VDF.GUI/VDF.GUI.csproj"
PROJECT_WEB="VDF.Web/VDF.Web.csproj"
DOTNET_VER="net9.0"
OUTPUT_BASE="dist"

# Cores para o terminal
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "${BLUE}🚀 Iniciando Build Multiplataforma (.NET 9)...${NC}"

# 1. Limpeza Total
echo "${YELLOW}🧹 1/5: Limpando builds anteriores e cache do NuGet...${NC}"
rm -rf "$OUTPUT_BASE"
rm -rf **/bin **/obj
dotnet nuget locals all --clear

# Função para Build de Desktop
build_desktop() {
    local RID=$1
    local PLATFORM_NAME=$2
    local TARGET_DIR="$OUTPUT_BASE/Desktop/$PLATFORM_NAME"
    
    echo "${GREEN}📦 Gerando pacotes para $PLATFORM_NAME ($RID)...${NC}"
    
    # 2. Executa o Publish (Sem SingleFile para garantir compatibilidade do Avalonia)
    dotnet publish "$PROJECT_GUI" \
        -c Release \
        -r "$RID" \
        --self-contained true \
        -p:UseAppHost=true \
        -o "$TARGET_DIR/_temp"

    if [[ "$RID" == osx-* ]]; then
        # --- Lógica macOS (.app) ---
        echo "   🍎 Criando Bundle .app..."
        local BUNDLE="$TARGET_DIR/$APP_NAME.app"
        mkdir -p "$BUNDLE/Contents/MacOS"
        mkdir -p "$BUNDLE/Contents/Resources"
        
        # Copia todos os arquivos da compilação para o MacOS
        cp -R "$TARGET_DIR/_temp/"* "$BUNDLE/Contents/MacOS/"
        cp "VDF.GUI/Assets/macOS/Info.plist" "$BUNDLE/Contents/"
        cp "VDF.GUI/Assets/macOS/icon.icns" "$BUNDLE/Contents/Resources/"
        
        # Permissões e Assinatura Ad-Hoc
        chmod +x "$BUNDLE/Contents/MacOS/$EXEC_NAME"
        xattr -cr "$BUNDLE"
        codesign --force --deep --sign - "$BUNDLE"
        
        rm -rf "$TARGET_DIR/_temp"
    
    elif [[ "$RID" == win-* ]]; then
        # --- Lógica Windows ---
        echo "   🪟 Organizando pasta Windows..."
        mv "$TARGET_DIR/_temp" "$TARGET_DIR/$APP_NAME"
        # O executável já estará lá como VDF.GUI.exe
        
    elif [[ "$RID" == linux-* ]]; then
        # --- Lógica Linux ---
        echo "   🐧 Organizando pasta Linux..."
        mv "$TARGET_DIR/_temp" "$TARGET_DIR/$APP_NAME"
        chmod +x "$TARGET_DIR/$APP_NAME/$EXEC_NAME"
    fi
}

# 2. Executar Builds Desktop
echo "${YELLOW}📦 2/5: Compilando Versões Desktop Multiplataforma...${NC}"
# Mac Intel
build_desktop "osx-x64" "Mac_Intel_x86_64"

# Mac ARM (Apple Silicon)
build_desktop "osx-arm64" "Mac_ARM_AppleSilicon"

# Windows x64
build_desktop "win-x64" "Windows_x64"

# Linux x64
build_desktop "linux-x64" "Linux_x64"

# 3. Build Web
echo "${YELLOW}🌐 3/5: Compilando Versão Web...${NC}"
dotnet publish "$PROJECT_WEB" \
    -c Release \
    -o "$OUTPUT_BASE/Web" \
    --self-contained true

# 4. Verificação Final
echo "${YELLOW}🔍 4/5: Estrutura gerada:${NC}"
ls -R "$OUTPUT_BASE"

echo "--------------------------------------------------------"
echo "${GREEN}✅ 5/5: SUCESSO! Todos os artefatos estão em: $OUTPUT_BASE${NC}"
echo "--------------------------------------------------------"

# Abre a pasta final se estiver no macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    open "$OUTPUT_BASE"
fi