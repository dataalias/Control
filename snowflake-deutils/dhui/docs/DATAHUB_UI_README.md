# 📊 DataHub Management System - Streamlit UI

A comprehensive web-based interface for managing DataHub operations with full CRUD capabilities, referential integrity enforcement, and activity logging.

## 🎯 Overview

This Streamlit application provides a complete management interface for the DataHub system, allowing users to:

- **Manage Publishers** - Create, update, delete, and view data providers
- **Handle Publications** - Manage data feeds and datasets with scheduling
- **Control Subscribers** - Manage data consumers and notification settings
- **Maintain Subscriptions** - Link publications to subscribers
- **Track Issues** - Monitor publication execution and status
- **Manage Reference Data** - Handle lookup tables and configuration
- **View Analytics** - System metrics and usage insights
- **Audit Activities** - Complete logging using StepLogger

## 🏗️ Architecture

### Database Schema Relationships

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Publishers    │────│  Publications   │────│     Issues      │
│                 │    │                 │    │                 │
│ - PublisherCode │    │ - PublicationCode│   │ - IssueId       │
│ - PublisherName │    │ - PublisherCode │    │ - PublicationCode│
│ - ContactName   │    │ - PublicationName│   │ - StatusCode    │
│ - InterfaceCode │    │ - IsActive      │    │ - ReportDate    │
│ - SecretKey     │    │ - GlueWorkflow  │    │ - RecordCount   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         v                       v                       v
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Subscribers   │────│  Subscriptions  │    │   Step Logger   │
│                 │    │                 │    │                 │
│ - SubscriberCode│    │ - SubscriptionCode│  │ - ProcessName   │
│ - SubscriberName│    │ - PublicationCode │  │ - StepName      │
│ - ContactId     │    │ - SubscriberCode │   │ - StepStatus    │
│ - InterfaceCode │    │ - IsActive       │   │ - StepDesc      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │
         │                       │
         v                       v
┌─────────────────┐    ┌─────────────────┐
│    Contact      │    │ Reference Data  │
│                 │    │                 │
│ - ContactId     │    │ - REF_Interface │
│ - ContactName   │    │ - REF_Status    │
│ - CompanyName   │    │ - REF_FileFormat│
│ - Email, Phone  │    │ - REF_Interval  │
└─────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

1. **Python 3.9+** installed
2. **Virtual environment** (recommended)
3. **AWS credentials** configured
4. **eimutils package** installed
5. **Access** to Snowflake DataHub database

### Installation

1. **Clone or navigate to the project directory:**
   ```bash
   cd /path/to/eim_deutils
   ```

2. **Create and activate virtual environment:**
   ```bash
   python -m venv datahub_env
   
   # Windows
   datahub_env\Scripts\activate
   
   # Linux/Mac
   source datahub_env/bin/activate
   ```

3. **Install dependencies:**
   ```bash
   # Option 1: Use the launcher (recommended)
   python launch_datahub_ui.py --install
   
   # Option 2: Manual installation
   pip install streamlit pydantic pandas snowflake-connector-python boto3
   pip install -e python/ --no-deps
   ```

### Launch Application

**Easy Launch (Recommended):**
```bash
python launch_datahub_ui.py
```

**Manual Launch:**
```bash
streamlit run python/eimutils/streamlit_datahub_complete.py
```

The application will open in your browser at `http://localhost:8501`

## 🔧 Configuration

### Connection Settings

In the sidebar, configure:

1. **Secret ARN** - AWS Secrets Manager ARN for database credentials
2. **Environment** - Target environment (DEV, STAGE, PROD)
3. **AWS Region** - AWS region for secrets and resources
4. **Database** - Snowflake database name (e.g., `ULTRA_DEV_RAW`)
5. **User ID** - Your user identifier for audit logging

### AWS Secrets Manager Format

Your secret should contain database connection details:
```json
{
  "host": "your-snowflake-account.snowflakecomputing.com",
  "username": "your-username",
  "password": "your-password",
  "database": "ULTRA_DEV_RAW",
  "schema": "DATA_HUB",
  "warehouse": "your-warehouse",
  "role": "your-role"
}
```

## 📋 Features

### Publishers Management

- **📋 List View**
  - Searchable and filterable publisher directory
  - Sort by code, name, or creation date
  - Export to CSV, JSON, or Excel
  - Real-time metrics dashboard

- **➕ Create Publisher**
  - Form validation with real-time feedback
  - Interface selection with descriptions
  - Referential integrity checks
  - Automatic audit logging

- **✏️ Update Publisher**
  - Load existing data for editing
  - Track field changes
  - Preserve audit history
  - Validation before save

- **🗑️ Delete Publisher**
  - Dependency checking before deletion
  - Confirmation requirements
  - Cascade impact analysis
  - Safe deletion with logging

- **📊 Analytics Dashboard**
  - Publisher distribution by interface type
  - Publication count analysis
  - Recent activity timeline
  - System health metrics

### Publications Management
*(Framework implemented - full UI available on request)*

- Publication scheduling and configuration
- File format and processing method setup
- SLA monitoring and alerting
- Glue workflow integration

### Subscribers Management
*(Framework implemented - full UI available on request)*

- Subscriber registration and configuration
- Notification endpoint setup
- Contact information management
- Interface type assignment

### Subscriptions Management
*(Framework implemented - full UI available on request)*

- Publication-to-subscriber mappings
- Delivery configuration
- Status monitoring
- Subscription analytics

### Issues Tracking
*(Framework implemented - full UI available on request)*

- Publication execution tracking
- Status monitoring and reporting
- Error analysis and resolution
- Performance metrics

### Reference Data Management

- **Interface Types** - Integration methods and protocols
- **Status Codes** - System status definitions
- **File Formats** - Supported data formats
- **Intervals** - Scheduling intervals
- **Transfer Methods** - Data transfer protocols
- **Storage Methods** - Data storage approaches

### System Analytics

- **📊 Real-time Metrics**
  - System component counts
  - Active vs inactive resources
  - Recent activity summaries
  - Health indicators

- **📈 Trend Analysis**
  - Usage patterns over time
  - Growth metrics
  - Performance trends
  - Error rate analysis

- **🔍 Activity Monitoring**
  - Step-by-step operation logs
  - User activity tracking
  - System event timeline
  - Error and warning alerts

## 🛡️ Security & Data Integrity

### Referential Integrity

The system enforces referential integrity through:

- **Pre-operation Validation** - Checks foreign key relationships
- **Dependency Analysis** - Identifies related records before deletion
- **Transaction Safety** - Atomic operations with rollback capability
- **Cascade Impact** - Shows downstream effects of changes

### Activity Logging

All operations are logged using the StepLogger system:

```python
# Example log entry
{
    "process_name": "StreamlitDataHubCRUD",
    "step_name": "Publisher Created", 
    "step_desc": {
        "PublisherCode": "ACME_CORP",
        "PublisherName": "ACME Corporation",
        "CreatedBy": "john.doe",
        "Timestamp": "2024-01-15T10:30:00Z"
    },
    "step_status": "SUCCESS"
}
```

### Data Validation

Pydantic models ensure data quality:

- **Type Validation** - Enforces correct data types
- **Length Limits** - Prevents data truncation
- **Required Fields** - Ensures critical data presence
- **Format Validation** - Validates emails, dates, codes
- **Business Rules** - Enforces domain-specific constraints

## 🔍 Troubleshooting

### Common Issues

1. **Connection Failed**
   ```
   Error: Failed to establish database connection
   ```
   - Check AWS credentials configuration
   - Verify Secret ARN and region
   - Ensure network connectivity to Snowflake
   - Validate secret content format

2. **Import Errors**
   ```
   ModuleNotFoundError: No module named 'eimutils'
   ```
   - Install eimutils: `pip install -e python/`
   - Verify virtual environment activation
   - Check Python path configuration

3. **Permission Denied**
   ```
   Error: Access denied to DATA_HUB schema
   ```
   - Verify database user permissions
   - Check role assignments in Snowflake
   - Ensure schema access grants

4. **Referential Integrity Violations**
   ```
   Validation failed: Publisher with code 'XYZ' does not exist
   ```
   - Create referenced records first
   - Check spelling and case sensitivity
   - Verify data consistency

### Performance Optimization

- **Connection Pooling** - Reuse database connections
- **Query Caching** - Cache reference data locally
- **Lazy Loading** - Load data on-demand
- **Batch Operations** - Group related operations

### Debugging

Enable debug mode by setting environment variable:
```bash
export STREAMLIT_DEBUG=true
python launch_datahub_ui.py
```

## 📊 Usage Examples

### Creating a New Publisher

1. Navigate to **Publishers** tab
2. Click **Create** sub-tab
3. Fill in required fields:
   - Publisher Code: `ACME_CORP`
   - Publisher Name: `ACME Corporation`
   - Contact Name: `John Smith`
   - Interface Code: `SFTP`
4. Click **Create Publisher**
5. System validates and logs the creation

### Setting Up a Publication

1. Create publisher first (if not exists)
2. Navigate to **Publications** tab
3. Configure publication details:
   - Link to existing publisher
   - Set file format and processing method
   - Configure scheduling parameters
   - Define SLA requirements

### Monitoring System Activity

1. Navigate to **System Analytics** tab
2. View real-time metrics dashboard
3. Check recent activity logs
4. Monitor system health indicators

## 🚧 Extension Points

The system is designed for easy extension:

### Adding New Tables

1. Create SQL schema in `Database/Control/Tables/`
2. Add Pydantic model in the UI code
3. Implement CRUD functions
4. Add UI components following the pattern

### Custom Analytics

1. Create new analytics queries
2. Add visualization components
3. Integrate with existing dashboard
4. Include in export functionality

### Integration Hooks

1. Add webhook endpoints for notifications
2. Implement external API integrations
3. Create custom validation rules
4. Add specialized logging formats

## 📞 Support

For questions or issues:

1. Check the **Help & Documentation** section in the sidebar
2. Review error messages and troubleshooting guide
3. Verify configuration and dependencies
4. Contact system administrators for access issues

## 🎯 Roadmap

Planned enhancements:

- **Advanced Analytics** - Machine learning insights
- **API Integration** - REST API for external systems
- **Automated Testing** - Comprehensive test suite
- **Performance Monitoring** - Real-time performance metrics
- **Multi-tenant Support** - Organization-based access control
- **Advanced Scheduling** - Complex scheduling scenarios
- **Data Lineage** - End-to-end data flow visualization

---

*DataHub Management System - Streamlining data operations with comprehensive CRUD capabilities and intelligent automation.*
