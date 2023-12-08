from setuptools import setup, find_packages

# ,  find_namespace_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name='deDataHub',
    version='3.3.2',
    author='',
    author_email='',
    description='This project is a wrapper library to call utility functions that interact with Data Hub.',
    long_description=long_description,
    long_description_content_type="text/markdown",
    url='https://git-codecommit.us-east-1.amazonaws.com/v1/repos/deDataHub',
    project_urls={},
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    packages=find_packages(),
    python_requires=">=3.6",
)
