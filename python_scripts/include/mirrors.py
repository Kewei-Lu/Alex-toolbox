from pick import pick
import requests
from lxml import etree


BASE_URL = "http://linux-ftp.sh.intel.com/pub"
OS_BASE_URL = BASE_URL


def select(prompt: str, choices: list) -> tuple:
    option, index = pick(choices, prompt)
    return (option, index)


def select_multiple(prompt: str, choices: list) -> tuple:
    option, index = pick(choices, prompt, multiselect=True)
    return (option, index)


def get_html(url: str):
    res = requests.get(url)
    html = etree.HTML(res.text)
    return html


def main():
    BASE_URL = input("BASE_URL: ")
    print(f"{BASE_URL}")
    mirrors_OSs = get_html(f"{BASE_URL}").xpath(
        r"//tr/td[@class='link']/a[contains(text(), '/') and not(contains(text(),'Parent directory'))]/@title")
    selected_repos, _ = select_multiple(
        "Which repo do you want to config", mirrors_OSs)
    if "rhel" in BASE_URL:
        res = ""
        template = '''
        [Interl_Internal_{os}]
        name=Red Hat Enterprise Linux OS (Internal) - $basearch
        enabled=1
        baseurl={BASE_URL}/BaseOS/$basearch/os/
        gpgcheck=0
        '''
        for repo in selected_repos:

    else:
        print("Not supported OS distro yet")
        return

        # RHEL/SUSE in ISO, others in mirrors

        # ISO_OSs = get_html(f"{BASE_URL}/ISO").xpath(
        #     r"//tr/td[@class='link']/a[contains(text(), '/') and not(contains(text(),'Parent directory'))]/@title")

    print(f"you are selecting {selected_repos}")


if __name__ == "__main__":
    main()
