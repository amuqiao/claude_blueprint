#!/usr/bin/env python3
"""
检查 OPENAI_API_KEY 环境变量是否有效

使用方法:
    python scripts/check_openai_key.py
    或
    ./scripts/check_openai_key.py
"""

import os
import sys
import json
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError


def check_openai_api_key():
    """检查 OPENAI_API_KEY 环境变量是否存在且有效"""

    # 检查环境变量是否存在
    api_key = os.environ.get("OPENAI_API_KEY")

    if not api_key:
        print("❌ 未找到 OPENAI_API_KEY 环境变量")
        print("\n请设置环境变量:")
        print("  export OPENAI_API_KEY='your-api-key'")
        return False

    # 显示部分 API key（安全显示）
    masked_key = f"{api_key[:7]}...{api_key[-4:]}" if len(api_key) > 11 else "***"
    print(f"✓ 找到 OPENAI_API_KEY: {masked_key}")

    # 验证 API key 有效性
    print("\n正在验证 API key...")

    try:
        url = "https://api.openai.com/v1/models"
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }

        request = Request(url, headers=headers)

        with urlopen(request, timeout=10) as response:
            data = json.loads(response.read().decode())

            if "data" in data:
                model_count = len(data["data"])
                print(f"✅ API key 有效！")
                print(f"✓ 可访问 {model_count} 个模型")

                # 显示一些常用模型
                common_models = ["gpt-4", "gpt-4-turbo", "gpt-3.5-turbo"]
                available_models = [m["id"] for m in data["data"]]

                print("\n常用模型可用性:")
                for model in common_models:
                    matching = [m for m in available_models if model in m]
                    if matching:
                        print(f"  ✓ {model}: {matching[0]}")

                return True

    except HTTPError as e:
        error_body = e.read().decode()
        try:
            error_data = json.loads(error_body)
            error_msg = error_data.get("error", {}).get("message", "未知错误")
        except:
            error_msg = error_body

        print(f"❌ API key 无效 (HTTP {e.code})")
        print(f"\n错误信息: {error_msg}")
        print("\n请检查:")
        print("  1. API key 是否正确")
        print("  2. 访问 https://platform.openai.com/api-keys 获取有效的 key")
        return False

    except URLError as e:
        print(f"❌ 网络连接失败: {e.reason}")
        print("\n请检查:")
        print("  1. 网络连接是否正常")
        print("  2. 是否需要配置代理")
        return False

    except Exception as e:
        print(f"❌ 验证失败: {str(e)}")
        return False


def main():
    """主函数"""
    print("=" * 50)
    print("OPENAI_API_KEY 验证工具")
    print("=" * 50)
    print()

    success = check_openai_api_key()

    print()
    print("=" * 50)

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
