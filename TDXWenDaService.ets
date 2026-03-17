/**
 * 通达信问答 - 数据服务层
 * 鸿蒙6.0版本
 */
import http from '@ohos.net.http';
import { BusinessError } from '@ohos.base';

export interface StockData {
  现价: string;
  涨跌幅: string;
  所属行业: string;
  涨停次数: string;
}

export class TDXWenDaService {
  private baseUrl: string = 'https://wenda.tdx.com.cn';

  /**
   * 搜索股票数据
   * 注意:由于通达信使用私有协议,此方法可能无法直接获取数据
   * 建议使用WebView方案
   */
  async searchStocks(question: string): Promise<StockData[]> {
    return new Promise((resolve, reject) => {
      const httpRequest = http.createHttp();
      
      const url = `${this.baseUrl}/site/wenda/stock_index.html?message=${encodeURIComponent(question)}`;
      
      httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'User-Agent': 'Mozilla/5.0 (Linux; HarmonyOS 6.0.0) AppleWebKit/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'zh-CN,zh;q=0.9'
        },
        connectTimeout: 60000,
        readTimeout: 60000
      }, (err: BusinessError, data: http.HttpResponse) => {
        if (!err) {
          if (data.responseCode === 200) {
            // 解析HTML(需要HTML解析库)
            const html = data.result as string;
            const stocks = this.parseHTML(html);
            resolve(stocks);
          } else {
            reject(new Error(`HTTP错误: ${data.responseCode}`));
          }
        } else {
          reject(new Error(`请求失败: ${err.message}`));
        }
        httpRequest.destroy();
      });
    });
  }

  /**
   * 解析HTML提取数据
   * 注意:鸿蒙没有内置HTML解析库,需要手动解析或使用第三方库
   */
  private parseHTML(html: string): StockData[] {
    const stocks: StockData[] = [];
    
    try {
      // 简单的字符串匹配(不推荐,建议使用WebView方案)
      const tableRegex = /<table[^>]*>([\s\S]*?)<\/table>/gi;
      const tableMatch = tableRegex.exec(html);
      
      if (tableMatch) {
        const rowRegex = /<tr[^>]*>([\s\S]*?)<\/tr>/gi;
        let rowMatch;
        
        while ((rowMatch = rowRegex.exec(tableMatch[1])) !== null) {
          const cellRegex = /<td[^>]*>([\s\S]*?)<\/td>/gi;
          const cells: string[] = [];
          let cellMatch;
          
          while ((cellMatch = cellRegex.exec(rowMatch[1])) !== null) {
            cells.push(this.stripHtmlTags(cellMatch[1]).trim());
          }
          
          if (cells.length >= 4) {
            stocks.push({
              现价: cells[0],
              涨跌幅: cells[1],
              所属行业: cells[2],
              涨停次数: cells[3]
            });
          }
        }
      }
    } catch (e) {
      console.error('HTML解析失败:', e);
    }
    
    return stocks;
  }

  /**
   * 移除HTML标签
   */
  private stripHtmlTags(html: string): string {
    return html.replace(/<[^>]*>/g, '');
  }

  /**
   * 使用WebView获取数据(推荐方案)
   * 返回JavaScript代码,在WebView中执行
   */
  getWebViewExtractScript(): string {
    return `
      (function() {
        try {
          const tables = document.querySelectorAll('table');
          if (tables.length > 0) {
            const rows = tables[0].querySelectorAll('tr');
            const data = [];
            
            for (let i = 1; i < rows.length; i++) {
              const cells = rows[i].querySelectorAll('td');
              if (cells.length >= 4) {
                data.push({
                  '现价': cells[0]?.textContent?.trim() || '',
                  '涨跌幅': cells[1]?.textContent?.trim() || '',
                  '所属行业': cells[2]?.textContent?.trim() || '',
                  '涨停次数': cells[3]?.textContent?.trim() || ''
                });
              }
            }
            
            return JSON.stringify(data);
          }
          return '[]';
        } catch (e) {
          return JSON.stringify({ error: e.message });
        }
      })();
    `;
  }
}
