*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Robocloud.Secrets
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Dialogs
Library           utilities.py
Library           Orders
Library           RPA.PDF
Library           RPA.Archive
Library           OperatingSystem
Variables         variables.py
Suite Teardown    Close All Browsers

*** Keywords ***
Validate prerequisites
    Variable Should Exist    ${WEBSITE_URL}
    Should Not Be Empty    ${WEBSITE_URL}
    Variable Should Exist    ${CSV_URL}
    Should Not Be Empty    ${CSV_URL}

Open the robot order website
    # Launch RobotSpareBin website, set screen size and maximize browser window
    Log    ${WEBSITE_URL}
    Open Available Browser    ${WEBSITE_URL}
    Set Window Size    1440    900
    Maximize Browser Window

Close the annoying modal
    # Close popup window which appears when site is opened
    Wait Until Element Is Visible    css:.modal-header
    Click Button    css:button.btn.btn-dark

Download CSV file
    # Download order backlog (CSV file) from website and store it to local file system
    Download    ${CSV_URL}    target_file=output/orders.csv    overwrite=True

Collect Order Row Count From User
    [Arguments]    ${CSV_ROW_COUNT}
    # Human in the loop
    # Assist provides amount of order rows in CSV and ask user how many orders should be done
    # This version does not include input validation for user input, so be kind and provide valid numeric input
    Create Form    How many Rrobot Orders
    Add Text Input    Order backlog (CVS) contains ${CSV_ROW_COUNT} orders. How many we should order now (1 - ${CSV_ROW_COUNT})    search
    &{response}=    Request Response
    [Return]    ${response["search"]}

Order Robots
    [Arguments]    ${orders}    ${USERRESPONSE}
    ${counter}=    Set Variable    0    # Set counter variable for exit loop
    FOR    ${row}    IN    @{orders}    # Loop Order Rows
        ${counter}=    Evaluate    ${counter} + 1    # Increment counter +1
        Exit For Loop If    ${counter} > ${USERRESPONSE}    # Exit loop if counter value > user input
        Wait Until Keyword Succeeds    3x    0.5s    Close the annoying modal
        Fill the form    ${row}    # Call anothet keyword to fill one order
        Preview the robot    # Click the preview button from order
        Wait Until Keyword Succeeds    10x    0.5 sec    Submit the order    # Submit order & retry possible errors
        ${pdf}=    Store the receipt as a PDF file    ${row}[order_number]    # Save order as PDF
        ${screenshot}=    Take a screenshot of the robot    ${row}[order_number]    # Download robot picture
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}    # Merge robot pictures to order PDF
        Go to order another robot    # Move to next Order
    END

Fill the form
    [Arguments]    ${order}
    # Select correct Robot parts and delivery address for each order
    Select From List By Value    id:head    ${order["head"]}
    Select Radio Button    body    ${order["body"]}
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order["legs"]}
    Input Text    id:address    ${order["address"]}

Preview the robot
    # Open preview screen of the Robot order
    Wait Until Element Is Visible    id:preview
    Click Button    Preview

Submit the order
    # Submit the order and wait receipt screen
    Click Button    Order
    Wait Until Element Is Visible    id:receipt

Store the receipt as a PDF file
    [Arguments]    ${order_nro}
    # Save order as PDF to local file system
    ${receipt_html}=    Get Element Attribute    //*[@id="receipt"]    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}receipts${/}Order-${order_nro}.pdf
    [Return]    ${OUTPUT_DIR}${/}receipts${/}Order-${order_nro}.pdf

Take a screenshot of the robot
    # Take screenshot from Robot preview and store picture to local file system
    [Arguments]    ${order_nro}
    Capture Element Screenshot    //*[@id="robot-preview-image"]    ${OUTPUT_DIR}${/}tmp${/}Image-${order_nro}.png
    [Return]    ${OUTPUT_DIR}${/}tmp${/}Image-${order_nro}.png

Embed the robot screenshot to the receipt PDF file
    # Merge robot picture to order PDF
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close Pdf    ${pdf}

Go to order another robot
    # Open new order form for next order
    Click Button    id:order-another

Create a ZIP file of the receipts
    # Zip all order PDF files as one Orders.zip
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${OUTPUT_DIR}${/}Orders.zip

Delete Previous Run Order Files
    # Delete PDF orders and Orders.zip from previous run
    Remove Files    ${OUTPUT_DIR}${/}receipts${/}*.pdf
    Remove Files    ${OUTPUT_DIR}${/}Orders.zip

Clean Temp Files from Filesystem
    # Clean local file system from temp files
    Remove Files    ${OUTPUT_DIR}${/}tmp${/}*.png
    Remove Files    ${OUTPUT_DIR}${/}orders.csv

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Delete Previous Run Order Files    # Delete PDF orders and Orders.zip from previous run
    Validate prerequisites    # Validate mandatory variables
    Download CSV file    # Download order backlog (orders.csv)
    ${ROWCOUNT}=    Calculate Csv Row Count    ${CSV_LOCAL_FILE_PATH}    # Count order rows in CSV (Python function)
    ${USERRESPONSE}=    Collect Order Row Count From User    ${ROWCOUNT}    # Human in the loop - ask how many robots should be ordered
    Open the robot order website    # Open RobotSpareBin website for robot orders
    ${orders}=    Get orders    ${CSV_LOCAL_FILE_PATH}    # Get content of the CSV (Python function)
    Order Robots    ${orders}    ${USERRESPONSE}    # Loop trough order backlog and order robots
    Create a ZIP file of the receipts    # Zip all the order receipts to one file
    Clean Temp Files from Filesystem    # Clean local file system from temp files
