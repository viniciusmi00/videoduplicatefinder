#!/bin/zsh

# Configurações de Nome e Caminhos
# Nota: Verifique se no seu Info.plist o campo CFBundleExecutable está como VDF.GUI ou VideoDuplicateFinder
APP_NAME="VideoDuplicateFinder"
EXEC_NAME="VDF.GUI" 
PROJECT_PATH="VDF.GUI/VDF.GUI.csproj"
RID="osx-x64"
DOTNET_VER="net9.0"

# Caminhos de Saída
PUBLISH_DIR="VDF.GUI/bin/Release/$DOTNET_VER/$RID/publish"
BUNDLE_ROOT="VDF.GUI/bin/Release/$DOTNET_VER/$RID"
BUNDLE_PATH="$BUNDLE_ROOT/$APP_NAME.app"

echo "🧹 1/6: Limpando ambientes antigos..."
rm -rf **/bin **/obj
rm -rf "$BUNDLE_PATH"

echo "📦 2/6: Restaurando dependências para Intel x64..."
dotnet restore "$PROJECT_PATH" -r $RID

echo "🔨 3/6: Compilando projeto (Modo Normal - Múltiplos Arquivos)..."
# Compilação padrão sem SingleFile para garantir compatibilidade com Avalonia no Mac
dotnet publish "$PROJECT_PATH" \
    -c Release \
    -r $RID \
    --no-restore \
    --self-contained true \
    -p:UseAppHost=true

if [ ! -d "$PUBLISH_DIR" ]; then
    echo "❌ Erro: Falha na compilação. Pasta de publicação não encontrada."
    exit 1
fi

echo "🏗️  4/6: Montando estrutura do Bundle .app..."
mkdir -p "$BUNDLE_PATH/Contents/MacOS"
mkdir -p "$BUNDLE_PATH/Contents/Resources"

# Copia TODOS os arquivos da publicação (DLLs, configs, bibliotecas nativas) para a pasta MacOS
echo "   -> Copiando arquivos de compilação..."
cp -R "$PUBLISH_DIR/"* "$BUNDLE_PATH/Contents/MacOS/"

# Copia os recursos de interface do macOS
echo "   -> Copiando Info.plist e Ícone..."
cp "VDF.GUI/Assets/macOS/Info.plist" "$BUNDLE_PATH/Contents/"
cp "VDF.GUI/Assets/macOS/icon.icns" "$BUNDLE_PATH/Contents/Resources/"

echo "🔐 5/6: Aplicando permissões e Assinatura Ad-Hoc..."
# Garante que o binário principal é executável
chmod +x "$BUNDLE_PATH/Contents/MacOS/$EXEC_NAME"

# Assina profundamente todos os binários e bibliotecas internas
# O sinal '-' indica assinatura ad-hoc, essencial para rodar no seu Hackintosh
codesign --force --deep --sign - "$BUNDLE_PATH"

echo "🧹 6/6: Removendo atributos de quarentena do sistema..."
xattr -cr "$BUNDLE_PATH"

echo "--------------------------------------------------------"
echo "✅ SUCESSO! Aplicativo gerado e assinado."
echo "📍 Local: $BUNDLE_PATH"
echo "--------------------------------------------------------"

# Abre a pasta para facilitar o acesso
open "$BUNDLE_ROOT"