# 通达信问答 - 鸿蒙6.0版本

## 📱 项目说明

本项目为通达信问答的鸿蒙6.0原生应用实现,使用ArkTS语言开发。

## 🎯 实现方案

### 方案1: WebView方案(推荐)

使用WebView加载通达信问答页面,通过JavaScript桥接提取数据。

**优势:**
- ✅ 实现简单
- ✅ 无需逆向协议
- ✅ 数据准确

**劣势:**
- ⚠️ 需要加载完整页面
- ⚠️ 速度较慢

### 方案2: HTTP请求方案(不推荐)

直接发送HTTP请求获取HTML,然后解析。

**问题:**
- ❌ 通达信使用私有TDXQuery协议
- ❌ 无法通过纯HTTP获取数据
- ❌ 鸿蒙没有内置HTML解析库

## 📂 文件结构

```
harmonyos/
├── TDXWenDa.ets              # 主页面(WebView方案)
├── TDXWenDaService.ets       # 数据服务层
├── README.md                 # 本文档
└── entry/
    └── src/
        └── main/
            ├── ets/
            │   └── pages/
            │       └── Index.ets
            └── resources/
                └── base/
                    └── element/
                        └── string.json
```

## 🚀 快速开始

### 1. 环境准备

- 安装DevEco Studio 4.0或更高版本
- 配置鸿蒙SDK(API 10+)
- 创建鸿蒙项目

### 2. 集成代码

1. 将`TDXWenDa.ets`复制到项目的`entry/src/main/ets/pages/`目录
2. 将`TDXWenDaService.ets`复制到`entry/src/main/ets/service/`目录
3. 在`module.json5`中添加网络权限:

```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET"
      }
    ]
  }
}
```

### 3. 使用示例

#### 主页面使用

```typescript
import { TDXWenDaPage } from './pages/TDXWenDa';

@Entry
@Component
struct Index {
  build() {
    Column() {
      TDXWenDaPage()
    }
  }
}
```

#### 服务层使用

```typescript
import { TDXWenDaService } from '../service/TDXWenDaService';

const service = new TDXWenDaService();

// 使用WebView方案(推荐)
const script = service.getWebViewExtractScript();
// 在WebView中执行script

// 使用HTTP方案(不推荐)
try {
  const stocks = await service.searchStocks('涨二停');
  console.log('获取到数据:', stocks.length);
} catch (e) {
  console.error('获取失败:', e);
}
```

## 📱 功能特性

### 已实现功能

- ✅ 搜索股票数据
- ✅ 数据列表展示
- ✅ 加载状态显示
- ✅ 错误处理
- ✅ WebView数据提取

### 待实现功能

- ⏳ 数据缓存
- ⏳ 批量搜索
- ⏳ 数据导出
- ⏳ 历史记录

## 🔧 核心代码说明

### 1. WebView配置

```typescript
// 启用JavaScript
this.webController.enableJavaScript();

// 注册桥接方法
this.webController.registerJavaScriptProxy(
  this.javaScriptBridge,
  'harmonyBridge',
  ['onDataReceived', 'onError']
);
```

### 2. 数据提取

```typescript
// 页面加载完成后执行
.onPageEnd(() => {
  this.webController.runJavaScript(this.getExtractDataScript());
})
```

### 3. JavaScript桥接

```typescript
javaScriptBridge = {
  onDataReceived: (data: string) => {
    const jsonData = JSON.parse(data);
    this.stockList = jsonData;
  },
  onError: (error: string) => {
    this.errorMsg = error;
  }
};
```

## ⚠️ 注意事项

### 1. 网络权限

必须在`module.json5`中添加网络权限:

```json
{
  "name": "ohos.permission.INTERNET"
}
```

### 2. WebView限制

- 需要启用JavaScript: `javaScriptAccess(true)`
- 需要启用DOM存储: `domStorageAccess(true)`
- 需要处理跨域问题

### 3. 数据提取时机

- 建议在`onPageEnd`回调中执行数据提取
- 需要等待数据加载完成(建议延迟3秒)

### 4. 错误处理

- 网络错误
- 页面加载错误
- 数据解析错误
- JavaScript执行错误

## 🎨 UI设计

### 主界面

- 标题栏: 蓝色背景,白色文字
- 搜索栏: 灰色背景,圆角输入框
- 数据列表: 卡片式布局,交替背景色
- 加载状态: LoadingProgress组件
- 错误提示: 红色背景,白色文字

### 数据项

- 序号: 左侧灰色文字
- 现价/涨跌幅: 主要信息,涨跌幅根据正负显示颜色
- 行业/涨停次数: 次要信息,灰色小字

## 📊 性能优化

### 1. WebView优化

```typescript
Web({ src: '', controller: this.webController })
  .width(0)
  .height(0)  // 隐藏WebView
  .cacheMode(CacheMode.Default)  // 启用缓存
```

### 2. 数据缓存

- 使用Preferences存储历史数据
- 使用LocalStorage缓存搜索结果

### 3. 列表优化

```typescript
List() {
  ForEach(this.stockList, (item, index) => {
    ListItem() {
      this.StockItem(item, index)
    }
  }, (item, index) => index.toString())
}
.lazyForEach()  // 懒加载
```

## 🔍 调试技巧

### 1. 查看WebView日志

```typescript
.onConsole((event) => {
  console.log('WebView Console:', event?.message.getMessage());
  return false;
})
```

### 2. 调试JavaScript

```typescript
.onPageEnd(() => {
  this.webController.runJavaScript(
    'console.log("页面加载完成");'
  );
})
```

### 3. 查看网络请求

```typescript
.onHttpErrorReceive((event) => {
  console.error('HTTP错误:', event?.request?.getRequestUrl());
})
```

## 📝 开发建议

1. **优先使用WebView方案** - 简单可靠
2. **添加错误处理** - 提升用户体验
3. **优化加载速度** - 使用缓存和懒加载
4. **适配不同屏幕** - 使用百分比布局
5. **测试网络环境** - 处理弱网情况

## 🆚 与其他平台对比

| 平台 | 实现方式 | 难度 | 性能 |
|------|---------|------|------|
| **鸿蒙原生** | WebView | ★★☆☆☆ | 中 |
| **Android** | WebView | ★★☆☆☆ | 中 |
| **iOS** | WKWebView | ★★☆☆☆ | 中 |
| **Python** | Selenium | ★★☆☆☆ | 慢 |
| **Python** | HTTP API | ★★★☆☆ | 快 |

## 📚 参考资料

- [鸿蒙开发文档](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/start-overview-0000001478061421-V3)
- [ArkTS语言规范](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/arkts-get-started-0000001504769321-V3)
- [WebView组件](https://developer.harmonyos.com/cn/docs/documentation/doc-references-V3/ts-basic-components-web-0000001477901205-V3)

## 🤝 贡献

欢迎提交Issue和Pull Request!

## 📄 许可证

MIT License
