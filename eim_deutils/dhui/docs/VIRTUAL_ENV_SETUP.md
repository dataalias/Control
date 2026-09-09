# 🎯 DataHub UI Virtual Environment Setup

This document describes the virtual environment setup for the DataHub Streamlit UI located in the `dhui/` directory.

## 📦 Virtual Environment Details

### Location
- **Directory**: `dhui/venv/`
- **Python Version**: Python 3.12.10
- **Package Manager**: pip 25.2

### Core Dependencies Installed

| Package | Version | Purpose |
|---------|---------|---------|
| **streamlit** | 1.50.0 | Web UI framework |
| **pandas** | 2.3.3 | Data processing and analysis |
| **pydantic** | 2.11.9 | Data validation and models |
| **snowflake-connector-python** | 3.17.4 | Snowflake database connectivity |
| **boto3** | 1.40.41 | AWS services integration |
| **pyarrow** | 21.0.0 | Fast data processing (Streamlit dependency) |
| **numpy** | 2.3.3 | Numerical computing |
| **eimutils** | 1.6.0 | Local DataHub utilities package |

### Supporting Dependencies
The following packages are automatically installed as dependencies:
- **requests** (2.32.5) - HTTP operations
- **cryptography** (46.0.0) - Secure connections
- **botocore** (1.40.41) - AWS core library
- **typing-extensions** (4.15.0) - Enhanced type hints
- **python-dateutil** (2.9.0) - Date/time handling
- **pytz** (2025.2) - Timezone support
- **jinja2** (3.1.6) - Template engine
- **tornado** (6.5.2) - Web server framework
- **watchdog** (6.0.0) - File system monitoring
- **altair** (5.5.0) - Statistical visualizations

## 🚀 Usage Instructions

### Activate Virtual Environment

**Windows (PowerShell):**
```powershell
dhui\venv\Scripts\Activate.ps1
```

**Windows (Command Prompt):**
```cmd
dhui\venv\Scripts\activate.bat
```

**Linux/Mac:**
```bash
source dhui/venv/bin/activate
```

### Launch DataHub UI

Once activated, you can launch the UI using:

**Option 1: Using the launcher script**
```bash
python launch_datahub_ui.py
```

**Option 2: Direct Streamlit launch**
```bash
streamlit run streamlit_datahub_complete.py
```

**Option 3: Basic UI version**
```bash
streamlit run streamlit_datahub.py
```

### Access the Interface
- Open your browser to: `http://localhost:8501`
- Configure connection settings in the sidebar
- Enter AWS Secret ARN for database credentials
- Select environment (DEV/STAGE/PROD) and region
- Click "Connect to DataHub"

## 🔧 Verification Commands

### Test All Imports
```bash
python -c "
import streamlit; print('✅ Streamlit:', streamlit.__version__)
import eimutils; print('✅ eimutils:', getattr(eimutils, '__version__', 'unknown'))
import pandas; print('✅ pandas:', pandas.__version__)
import pydantic; print('✅ pydantic:', pydantic.__version__)
print('All dependencies working!')
"
```

### Test eimutils Components
```bash
python -c "
from eimutils.step_logger import StepLogger
from eimutils.utils import get_snowflake_connection_from_secret
print('✅ eimutils components available')
"
```

### List Installed Packages
```bash
pip list
```

## 🏗️ Directory Structure

```
dhui/
├── venv/                          # Virtual environment
│   ├── Scripts/                   # Windows executables
│   │   ├── Activate.ps1          # PowerShell activation
│   │   ├── activate.bat          # Command prompt activation
│   │   └── python.exe            # Python executable
│   └── Lib/                      # Python packages
├── streamlit_datahub.py          # Basic DataHub UI
├── streamlit_datahub_complete.py # Full-featured DataHub UI
├── launch_datahub_ui.py          # UI launcher script
├── demo_datahub_features.py      # Feature demonstration
├── requirements.txt              # Package list for reference
├── setup_venv.py                 # Automated setup script
├── pyproject.toml                # Project configuration
└── DATAHUB_UI_README.md          # Complete documentation
```

## 🔄 Maintenance

### Update Dependencies
```bash
pip install --upgrade streamlit pandas pydantic snowflake-connector-python boto3
```

### Reinstall eimutils (if updated)
```bash
pip install -e ../python --no-deps --force-reinstall
```

### Recreate Virtual Environment (if needed)
```bash
# Remove old environment
rmdir /s venv  # Windows
rm -rf venv    # Linux/Mac

# Recreate
python -m venv venv
venv\Scripts\Activate.ps1  # Windows
pip install --upgrade pip
pip install streamlit pandas pydantic snowflake-connector-python boto3
pip install -e ../python --no-deps
```

## 🛠️ Troubleshooting

### Common Issues

**1. Import Errors**
- Ensure virtual environment is activated
- Check that eimutils is installed: `pip show eimutils`
- Verify Python path points to venv Python

**2. Connection Issues**
- Check AWS credentials configuration
- Verify network connectivity to Snowflake
- Ensure Secret ARN is valid and accessible

**3. Streamlit Not Starting**
- Check port 8501 is available
- Try alternative port: `streamlit run app.py --server.port 8502`
- Verify firewall settings

**4. Package Conflicts**
- Use `pip list` to check for version conflicts
- Consider recreating the virtual environment
- Use `pip install --force-reinstall` for specific packages

### Performance Optimization

**Memory Usage:**
- Close unused browser tabs
- Restart Streamlit app if memory usage grows
- Use data caching in Streamlit with `@st.cache_data`

**Loading Speed:**
- Enable caching for database queries
- Use `st.spinner()` for long-running operations
- Load reference data once at startup

## 📞 Support

For issues with:
- **Virtual Environment**: Check Python installation and permissions
- **Package Installation**: Verify internet connectivity and pip configuration  
- **DataHub UI**: See `DATAHUB_UI_README.md` for detailed documentation
- **eimutils Package**: Check `../python/` directory for source code

## 🎯 Next Steps

1. **Test the Setup**: Run the verification commands above
2. **Launch the UI**: Use one of the launch methods
3. **Configure Connection**: Set up your database credentials
4. **Explore Features**: Try the demo script or browse the UI tabs
5. **Read Documentation**: See `DATAHUB_UI_README.md` for complete usage guide

---

*Virtual environment successfully configured for DataHub Streamlit UI with all required dependencies and eimutils integration!*
