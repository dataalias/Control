from datetime import datetime
from typing import Optional


class StepLogDescriptionResult:
    """Result object to hold the output values from
    create_step_log_description"""
    def __init__(self, json_msg: str = '{}', format_error_msg: str = '{}',
                 duration: int = -1):
        self.json_msg = json_msg
        self.format_error_msg = format_error_msg
        self.duration = duration


def create_step_log_description(
    message_type: str = 'INFO',
    start_dtm: Optional[datetime] = None,
    end_dtm: Optional[datetime] = None,
    step_number: str = '0',
    operation: str = 'Unknown',
    step_description: str = 'N/A',
    json_snippet: str = 'N/A',
    err_num: int = 0,
    err_msg: str = 'N/A',
    parameters_passed_char: str = 'N/A',
    step_log_id: int = -1,
    etl_execution_id: int = -1,
    path_id: int = -1,
    verbose: bool = False
) -> StepLogDescriptionResult:
    """
    Creates JSON formatted log descriptions for audit purposes.

    This is a Python conversion of the SQL stored procedure
    audit.usp_CreateStepLogDescription.

    Args:
        message_type: Type of message ('INFO', 'WARN', 'ErrSQL', 'ErrCust')
        start_dtm: Start datetime
        end_dtm: End datetime
        step_number: Step number as string
        operation: Operation description
        step_description: Step description
        json_snippet: Additional JSON data
        err_num: Error number
        err_msg: Error message
        parameters_passed_char: Parameters passed description
        step_log_id: Step log ID
        etl_execution_id: ETL execution ID
        path_id: Path ID
        verbose: Enable verbose output

    Returns:
        StepLogDescriptionResult object containing json_msg, format_error_msg,
        and duration
    """

    # Initialize variables
    CRLF = '\r\n'
    TAB = '\t'
    TAB2 = '\t\t'
    current_dtm = datetime.now()
    
    # Handle None values with defaults
    if start_dtm is None:
        start_dtm = datetime(1900, 1, 1)
    if end_dtm is None:
        end_dtm = datetime(1900, 1, 1)
    
    # Initialize output variables
    json_msg = '{}'
    format_error_msg = '{}'
    duration = -1
    
    # Build parameters passed string
    start_str = start_dtm.strftime('%d %b %Y %H:%M:%S:%f')[:-3] if start_dtm else 'NULL'
    end_str = end_dtm.strftime('%d %b %Y %H:%M:%S:%f')[:-3] if end_dtm else 'NULL'
    
    parameters_passed_formatted = (
        f"{CRLF}***** Parameters Passed to create_step_log_description{CRLF}"
        f"     message_type = '{message_type or 'NULL'}'{CRLF}"
        f"    ,start_dtm = '{start_str}'{CRLF}"
        f"    ,end_dtm = '{end_str}'{CRLF}"
        f"    ,step_number = '{step_number or 'NULL'}'{CRLF}"
        f"    ,operation = '{operation or 'NULL'}'{CRLF}"
        f"    ,step_description = '{step_description or 'NULL'}'{CRLF}"
        f"    ,json_snippet = '{json_snippet or 'NULL'}'{CRLF}"
        f"    ,err_num = '{err_num}'{CRLF}"
        f"    ,err_msg = '{err_msg or 'NULL'}'{CRLF}"
        f"    ,parameters_passed_char = '{parameters_passed_char or 'NULL'}'{CRLF}"
        f"    ,step_log_id = {step_log_id}{CRLF}"
        f"    ,etl_execution_id = {etl_execution_id}{CRLF}"
        f"    ,path_id = {path_id}{CRLF}"
        f"    ,verbose = {verbose}{CRLF}"
        f"***** End of Parameters{CRLF}"
    )

    if verbose:
        print(parameters_passed_formatted)
    
    try:
        # Calculate duration in seconds
        if (start_dtm and end_dtm and start_dtm != datetime(1900, 1, 1) and
                end_dtm != datetime(1900, 1, 1)):
            duration = int((end_dtm - start_dtm).total_seconds())
        
        # Handle different message types
        if message_type.upper() in ('ERRSQL', 'ERRCUST'):
            # Error message handling

            # Check if JSON snippet is empty/null
            if not json_snippet or json_snippet in ('N/A', ''):
                # Without custom JSON snippet
                step_desc = (step_description if step_description != 'N/A' 
                           else message_type + ' thrown from process.')
                
                format_error_msg = (
                    f"{{{CRLF}{TAB}\"MessageType\":\"{message_type}\",{CRLF}"
                    f"{TAB}\"Error\" : {{{CRLF}"
                    f"{TAB2}\"ErrorNumber\":{err_num},{CRLF}"
                    f"{TAB2}\"ErrorMessage\":\"{_escape_quotes(err_msg)}\",{CRLF}"
                    f"{TAB2}\"ErrorTime\":\"{current_dtm.strftime('%Y-%m-%d %H:%M:%S')}\",{CRLF}"
                    f"{TAB2}\"StepLogId\":{step_log_id if step_log_id != -1 else -1},{CRLF}"
                    f"{TAB2}\"ParamentersPassed\":\"{parameters_passed_formatted}\"{CRLF}"
                    f"{TAB}}},{CRLF}"
                    f"{TAB}\"ProcessStepNumber\":{step_number},{CRLF}"
                    f"{TAB}\"Description\":\"{step_desc}\"{CRLF}"
                    f"}}"
                )
                
                json_msg = (
                    f'{{"MessageType":"{message_type}",'
                    f'"Error" : {{"ErrorNumber":{err_num},'
                    f'"ErrorMessage":"{_escape_quotes(err_msg)}",'
                    f'"ErrorTime":"{current_dtm.strftime('%Y-%m-%d %H:%M:%S')}",'
                    f'"StepLogId":{step_log_id if step_log_id != -1 else -1},'
                    f'"ParamentersPassed":"{parameters_passed_formatted.replace(CRLF, '')}"}},'
                    f'"ProcessStepNumber":{step_number},'
                    f'"Description":"{step_desc}"}}'
                )
            else:
                # With custom JSON snippet
                step_desc = (step_description if step_description != 'N/A' 
                           else message_type + ' thrown from process.')
                
                format_error_msg = (
                    f"{{{CRLF}{TAB}\"MessageType\":\"{message_type}\",{CRLF}"
                    f"{TAB}\"Error\" : {{{CRLF}"
                    f"{TAB2}\"ErrorNumber\":{err_num},{CRLF}"
                    f"{TAB2}\"ErrorMessage\":\"{_escape_quotes(err_msg)}\",{CRLF}"
                    f"{TAB2}\"ErrorTime\":\"{current_dtm.strftime('%Y-%m-%d %H:%M:%S')}\",{CRLF}"
                    f"{TAB2}\"StepLogId\":{step_log_id if step_log_id != -1 else -1},{CRLF}"
                    f"{TAB2}\"ParamentersPassed\":\"{parameters_passed_formatted}\"{CRLF}"
                    f"{TAB}}},{CRLF}"
                    f"{TAB}\"ProcessStepNumber\":{step_number},{CRLF}"
                    f"{TAB}\"Description\":\"{step_desc}\",{CRLF}"
                    f"{TAB}\"Custom\":{json_snippet}{CRLF}"
                    f"}}"
                )
                
                json_msg = (
                    f'{{"MessageType":"{message_type}",'
                    f'"Error" : {{"ErrorNumber":{err_num},'
                    f'"ErrorMessage":"{_escape_quotes(err_msg)}",'
                    f'"ErrorTime":"{current_dtm.strftime('%Y-%m-%d %H:%M:%S')}",'
                    f'"StepLogId":{step_log_id if step_log_id != -1 else -1},'
                    f'"ParamentersPassed":"{parameters_passed_formatted}"}},'
                    f'"ProcessStepNumber":{step_number},'
                    f'"Description":"{step_desc}",'
                    f'"Custom":{json_snippet}}}'
                )

        elif message_type.upper() in ('INFO', 'WARN'):
            # Info/Warning message handling

            if not json_snippet or json_snippet in ('N/A', ''):
                # Without custom JSON snippet
                step_desc = (step_description if step_description != 'N/A' 
                           else 'Step Completed')
                json_msg = (
                    f'{{"MessageType":"{message_type}",'
                    f'"StepNumber":{step_number},'
                    f'"Operation":"{operation}",'
                    f'"Description":"{step_desc}"}}'
                )
            else:
                # With custom JSON snippet
                step_desc = (step_description if step_description != 'N/A' 
                           else 'Step Completed')
                json_msg = (
                    f'{{"MessageType":"{message_type}",'
                    f'"StepNumber":{step_number},'
                    f'"Operation":"{operation}",'
                    f'"Description":"{step_desc}",'
                    f'"Custom":{json_snippet}}}'
                )

        else:
            # Handle all other message types
            json_msg = (
                f'{{"MessageType":"{message_type or 'Unknown'}",'
                f'"StepNumber":{step_number or -1},'
                f'"Operation":"{operation or 'Unknown'}",'
                f'"Description":"{step_description or 'Unknown'}"}}'
            )

        # Handle % escaping in format_error_msg (SQL Server specific behavior)
        if '%' in format_error_msg:
            format_error_msg = format_error_msg.replace('%', '%%')

        # Truncate if too long (SQL Server limit was 2047)
        if len(format_error_msg) > 2047:
            format_error_msg = format_error_msg[:2030] + '<Truncated>'

    except Exception as e:
        # Error handling equivalent to the SQL CATCH block
        error_num = 50000  # Custom error number
        error_msg = f"Error in create_step_log_description: {str(e)}"

        json_msg = (
            f'{{"MessageType":"ERROR","Error":{{"ErrorNumber":{error_num},'
            f'"ErrorType":"Python Error",'
            f'"ErrorMessage":"{_escape_quotes(error_msg)}",'
            f'"ParamentersPassed":"{_escape_quotes(parameters_passed_formatted)}"}},'
            f'"StepNumber":{step_number},'
            f'"Description":"Failure in create_step_log_description function"}}'
        )

        # In Python we might choose to raise the exception or return error info
        # For this conversion, we'll return the error in the JSON message
        print(f"Error in create_step_log_description: {e}")

    return StepLogDescriptionResult(json_msg, format_error_msg, duration)


def _escape_quotes(text: str) -> str:
    """Helper function to escape quotes in text for JSON"""
    if text is None:
        return ''
    return str(text).replace('"', "'")


# Test function equivalent to the SQL test example
def test_create_step_log_description():
    """Test function demonstrating usage"""
    start_dtm = datetime.now()
    # Roughly +.013 days equivalent
    end_dtm = datetime.now().replace(microsecond=start_dtm.microsecond + 13000)

    result = create_step_log_description(
        message_type='INFO',  # Could also test with 'ErrCust'
        start_dtm=start_dtm,
        end_dtm=end_dtm,
        step_number='5',
        operation='Insert',
        step_description='Neat Description',
        json_snippet='{"hi":"bye"}',
        err_num=0,
        err_msg='I failed as a person',
        parameters_passed_char='Parameters ...',
        step_log_id=-1,
        etl_execution_id=-1,
        path_id=-1,
        verbose=False
    )

    print(f'format_error_msg: {result.format_error_msg or "null"}')
    print(f'json_msg: {result.json_msg or "null"}')
    duration_str = result.duration if result.duration != -1 else "null"
    print(f'duration: {duration_str}')

    return result


if __name__ == "__main__":
    # Run the test
    test_create_step_log_description()
