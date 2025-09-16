import sys
import bs4
import requests as req

def get_coords_dict(soup):
    coordDict = {(int(s[0].text), int(s[2].text)): s[1].text for s in [r.select("span") for r in soup.select("tr")[1:]]}
    max_x = max(coordDict.keys(), key=lambda x: x[0])[0]
    max_y = max(coordDict.keys(), key=lambda x: x[1])[1]
 
    return max_x, max_y, coordDict

def parse_doc(url):
    
    data = req.get(url)
    html_content = data.text
    
    soup = bs4.BeautifulSoup(html_content, 'html.parser')
    max_x, max_y, coordDict = get_coords_dict(soup)
    
    # print the grid
    for y in range(max_y, -1, -1):
        row = ""
        for x in range(max_x + 1):
            row += coordDict.get((x, y), " ")
        print(row)
        

def main():
    url = "https://docs.google.com/document/d/e/2PACX-1vRPzbNQcx5UriHSbZ-9vmsTow_R6RRe7eyAU60xIF9Dlz-vaHiHNO2TKgDi7jy4ZpTpNqM7EvEcfr_p/pub"
    if len(sys.argv) > 1:
        url = sys.argv[1]
    parse_doc(url)
    
if __name__ == "__main__":
    main()