/**
 * 通达信问答 - 鸿蒙6.0版本
 * 使用WebView加载页面并提取数据
 */
import web_webview from '@ohos.web.webview';
import { CommonDataSource } from '../common/CommonDataSource';

// 数据模型
interface StockData {
  现价: string;
  涨跌幅: string;
  所属行业: string;
  涨停次数: string;
}

@Entry
@Component
struct TDXWenDaPage {
  // WebView控制器
  private webController: web_webview.WebviewController = new web_webview.WebviewController();
  
  // 搜索关键词
  @State searchQuestion: string = '涨二停';
  
  // 数据列表
  @State stockList: StockData[] = [];
  
  // 加载状态
  @State isLoading: boolean = false;
  
  // 错误信息
  @State errorMsg: string = '';

  aboutToAppear() {
    // 配置WebView
    this.configureWebView();
  }

  // 配置WebView
  configureWebView() {
    try {
      // 启用JavaScript
      this.webController.enableJavaScript();
      
      // 注册JavaScript桥接方法
      this.webController.registerJavaScriptProxy(
        this.javaScriptBridge,
        'harmonyBridge',
        ['onDataReceived', 'onError']
      );
    } catch (error) {
      console.error('WebView配置失败:', error);
    }
  }

  // JavaScript桥接对象
  javaScriptBridge = {
    // 接收数据回调
    onDataReceived: (data: string) => {
      console.info('收到数据:', data);
      try {
        const jsonData = JSON.parse(data);
        this.stockList = jsonData;
        this.isLoading = false;
        this.errorMsg = '';
      } catch (e) {
        console.error('数据解析失败:', e);
        this.errorMsg = '数据解析失败';
        this.isLoading = false;
      }
    },
    
    // 错误回调
    onError: (error: string) => {
      console.error('JavaScript错误:', error);
      this.errorMsg = error;
      this.isLoading = false;
    }
  };

  // 执行搜索
  performSearch() {
    if (!this.searchQuestion.trim()) {
      this.errorMsg = '请输入搜索关键词';
      return;
    }

    this.isLoading = true;
    this.errorMsg = '';
    this.stockList = [];

    // 构建URL
    const url = `https://wenda.tdx.com.cn/site/wenda/stock_index.html?message=${encodeURIComponent(this.searchQuestion)}`;
    
    // 加载页面
    this.webController.loadUrl(url);
  }

  // 提取数据的JavaScript代码
  getExtractDataScript(): string {
    return `
      (function() {
        try {
          // 等待数据加载
          setTimeout(function() {
            // 尝试从表格提取数据
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
              
              // 回调鸿蒙
              if (window.harmonyBridge && window.harmonyBridge.onDataReceived) {
                window.harmonyBridge.onDataReceived(JSON.stringify(data));
              }
            } else {
              // 尝试其他提取方式
              const items = document.querySelectorAll('[class*="item"], [class*="row"]');
              const data = [];
              
              items.forEach(item => {
                const text = item.textContent?.trim();
                if (text) {
                  data.push({ '内容': text });
                }
              });
              
              if (window.harmonyBridge && window.harmonyBridge.onDataReceived) {
                window.harmonyBridge.onDataReceived(JSON.stringify(data));
              }
            }
          }, 3000); // 等待3秒确保数据加载
        } catch (e) {
          if (window.harmonyBridge && window.harmonyBridge.onError) {
            window.harmonyBridge.onError(e.message);
          }
        }
      })();
    `;
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('通达信问答')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
      }
      .width('100%')
      .height(60)
      .backgroundColor('#007DFF')
      .justifyContent(FlexAlign.Center)
      .padding({ left: 20, right: 20 })

      // 搜索栏
      Row() {
        TextInput({ placeholder: '请输入搜索关键词', text: this.searchQuestion })
          .width('70%')
          .height(40)
          .onChange((value: string) => {
            this.searchQuestion = value;
          })
          .borderRadius(8)

        Button('搜索')
          .width('25%')
          .height(40)
          .onClick(() => {
            this.performSearch();
          })
          .borderRadius(8)
          .margin({ left: 10 })
      }
      .width('100%')
      .padding(15)
      .backgroundColor('#F5F5F5')

      // 加载状态
      if (this.isLoading) {
        Row() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#007DFF')
          
          Text('正在加载...')
            .fontSize(16)
            .margin({ left: 10 })
        }
        .width('100%')
        .height(100)
        .justifyContent(FlexAlign.Center)
      }

      // 错误信息
      if (this.errorMsg) {
        Row() {
          Text('❌ ' + this.errorMsg)
            .fontSize(14)
            .fontColor('#FF0000')
        }
        .width('100%')
        .padding(15)
        .backgroundColor('#FFECEC')
      }

      // 数据列表
      if (this.stockList.length > 0) {
        List() {
          ForEach(this.stockList, (item: StockData, index: number) => {
            ListItem() {
              this.StockItem(item, index)
            }
          }, (item: StockData, index: number) => index.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .divider({ strokeWidth: 1, color: '#E0E0E0' })
      }

      // WebView(隐藏)
      Web({ src: '', controller: this.webController })
        .width(0)
        .height(0)
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .onPageEnd(() => {
          // 页面加载完成后执行数据提取
          this.webController.runJavaScript(this.getExtractDataScript());
        })
        .onErrorReceive((event) => {
          this.errorMsg = '页面加载失败: ' + event?.error?.getErrorInfo();
          this.isLoading = false;
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  // 股票数据项组件
  @Builder
  StockItem(item: StockData, index: number) {
    Row() {
      // 序号
      Text((index + 1).toString())
        .width(40)
        .fontSize(14)
        .fontColor('#666666')
        .textAlign(TextAlign.Center)

      // 数据内容
      Column() {
        Row() {
          Text('现价: ' + item.现价)
            .fontSize(14)
            .fontColor('#333333')
          
          Text('  涨跌幅: ' + item.涨跌幅)
            .fontSize(14)
            .fontColor(item.涨跌幅.includes('-') ? '#00AA00' : '#FF0000')
        }
        .width('100%')
        .margin({ bottom: 5 })

        Row() {
          Text('行业: ' + item.所属行业)
            .fontSize(12)
            .fontColor('#666666')
          
          Text('  涨停次数: ' + item.涨停次数)
            .fontSize(12)
            .fontColor('#666666')
        }
        .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 10 })
    }
    .width('100%')
    .padding(15)
    .backgroundColor(index % 2 === 0 ? '#FFFFFF' : '#F9F9F9')
  }
}
