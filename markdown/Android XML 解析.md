# Android XML 解析

Tags : zazen android

---

[TOC]

---


Android中极力推荐用PULL的方式来解析

## SAX

- 调用方式(固定的写法)
```
public void parser(String value) {
    SAXParserFactory factory = SAXParserFactory.newInstance();
    XMLReader xmlReader;
    try {
        xmlReader = factory.newSAXParser().getXMLReader();
        xmlReader.setContentHandler(new ContentParserHandler());
        if (!TextUtils.isEmpty(value)) {
            xmlReader.parse(new InputSource(new StringReader(value)));
        }
    } catch (Exception e) {
        e.printStackTrace();
    }
}
```

- 通过继承DefaultHandler 来处理xml
```
public class ContentParserHandler extends DefaultHandler {
    private String value = "";
    @Override
    public void startDocument() throws SAXException {
        super.startDocument();
        // 开始解析一个xml文件时触发
    }
    @Override
    public void endDocument() throws SAXException {
        super.endDocument();
        // 结束解析一个xml文件时触发
    }

    @Override
    public void startElement(String uri, String localName, String qName, Attributes attributes) throws SAXException {
        super.startElement(uri, localName, qName, attributes);
        // 开始解析xml中的一个标签时触发，获取标签名和其中的各个属性值
    }

    @Override
    public void endElement(String uri, String localName, String qName) throws SAXException {
        super.endElement(uri, localName, qName);
        ZLog.i(ZTag.TAG_XML, "qName : %s; value : %s", qName, value);
        // 结束解析一个标签时触发
    }
    
        @Override
    public void characters(char[] ch, int start, int length) throws SAXException {
        super.characters(ch, start, length);
        // 解析一个标签内部的内容时触发，获取标签子节点中的内容
        value = new String(ch, start, length);
    }
}

```

## PULL

PULL方式没有回调, 通过getEventType()来获取状态, 内部逻辑需要开发者来处理

```
public void parser(int xmlId) {
    XmlResourceParser parser = context.getResources().getXml(xmlId);
    try {
        int eventType = parser.getEventType();
        while (eventType != XmlPullParser.END_DOCUMENT) {
            tagName = parser.getName();
            switch (eventType) {
                case XmlPullParser.START_DOCUMENT:
                    startDocument();
                    break;
                case XmlPullParser.START_TAG:
                    startElement();
                    break;
                case XmlPullParser.TEXT:
                    characters();
                    break;
                case XmlPullParser.END_TAG:
                    endElement();
                    break;
                default:
                    break;
            }
            eventType = parser.next();
            ZLog.i(ZTag.TAG_DEBUG, "" + parser.getName());
        }
        endDocument();
    } catch (XmlPullParserException | IOException e) {
        e.printStackTrace();
    }
}
```






