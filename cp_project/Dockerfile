FROM python:3
MAINTAINER  Tomer Leibovich "tomer.leibovich@gmail.com"
COPY requirement.txt ./
RUN pip install -r requirement.txt
WORKDIR /mysite
COPY mysite/ .
CMD ["python", "site.py"]
