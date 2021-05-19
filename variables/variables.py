from RPA.Robocloud.Secrets import Secrets

# Set global variable for local file path for Order backlog (CSV file)
CSV_LOCAL_FILE_PATH = "./output/orders.csv"

# Use vault to store secret URLs for RobotSpareBin website and Order backlog (CSV file)
secrets = Secrets()
WEBSITE_URL = secrets.get_secret("ROBOTSPAREBIN")["WEBSITE_URL"]
CSV_URL = secrets.get_secret("ROBOTSPAREBIN")["CSV_URL"]
