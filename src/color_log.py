import logging


class CustomFormatter(logging.Formatter):
    """Logging Formatter to add colors and my format"""

    white = "\033[37m"
    cyan = "\033[34m"
    yellow = "\033[33m"
    red = "\033[31m"
    bold_red = "\033[31;1m"
    reset = "\033[0m"
    format = "[%(levelname)s] %(message)s"

    FORMATS = {
        logging.DEBUG: white + format + reset,
        logging.INFO: cyan + format + reset,
        logging.WARNING: yellow + format + reset,
        logging.ERROR: red + format + reset,
        logging.CRITICAL: bold_red + format + reset
    }

    def format(self, record):
        """Add my style to original logging"""

        log_fmt = self.FORMATS.get(record.levelno)
        formatter = logging.Formatter(log_fmt)
        return formatter.format(record)


# create logger
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

# create console handler with a higher log level
ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)
ch.setFormatter(CustomFormatter())
logger.addHandler(ch)


def log(log_type, message):
    """Log function to export"""

    if log_type == 'debug':
        logger.debug(message)
    elif log_type == 'info':
        logger.info(message)
    elif log_type == 'warning':
        logger.warning(message)
    elif log_type == 'error':
        logger.error(message)
    elif log_type == 'critical':
        logger.critical(message)
