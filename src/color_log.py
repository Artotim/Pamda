import logging


class CustomFormatter(logging.Formatter):
    """Logging Formatter to add colors and my format"""

    white = "\033[37m"
    cyan = "\033[34m"
    yellow = "\033[33m"
    red = "\033[31m"
    bold_red = "\033[31;1m"
    reset = "\033[0m"
    level = "[%(levelname)s]   "
    msg = "%(message)s"

    FORMATS = {
        logging.DEBUG: white + level + msg + reset,
        logging.INFO: cyan + level + white + msg + reset,
        logging.WARNING: yellow + level + white + msg + reset,
        logging.ERROR: red + level + msg + reset,
        logging.CRITICAL: bold_red + level + msg + reset
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

    for line in message.split("\n"):
        if log_type == 'debug':
            logger.debug(line)
        elif log_type == 'info':
            logger.info(line)
        elif log_type == 'warning':
            logger.warning(line)
        elif log_type == 'error':
            logger.error(line)
        elif log_type == 'critical':
            logger.critical(line)


class DockerLogger:
    """Custom logger to  display correct path from inside docker container"""

    def __init__(self):
        self.docker_path = None
        self.user_path = None

    def __call__(self, *args, **kwargs):
        log_type = kwargs['log_type']
        message = kwargs['message']

        if self.docker_path:
            message = message.replace(self.user_path, self.docker_path)

        log(log_type, message)

    def set_paths(self, user_path, docker_path):
        self.docker_path = docker_path
        self.user_path = user_path or docker_path


docker_logger = DockerLogger()
