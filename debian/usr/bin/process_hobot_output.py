import sys
import re

def parse_and_sort():
    sections = []
    current_section = []
    current_header = None

    # print("################ in parse_and_sort ################")
    # 需要排序的区块标识（严格匹配）
    sort_headers = {
        '#EST Timing',
        '#STD(DMT) Timing',
        '#CEA Timing'
    }

    # 处理输入并分块
    for line in sys.stdin:
        # line = line.rstrip('\n')
        line = line.rstrip()
        if line.startswith('#'):
            if current_header is not None:
                sections.append((current_header, current_section))
            current_header = line
            current_section = []
        else:
            current_section.append(line)
    
    if current_header is not None:
        sections.append((current_header, current_section))

    # print("################ in parse_and_sort ################")
    # 处理每个区块
    processed = []
    for header, lines in sections:
        # print(f"fuhua - check {header}")
        # print(f"fuhua - check {lines}")
        processed.append(header)
        if header not in sort_headers:
            processed.extend(lines)
            continue
        
        entries = []
        other_lines = []
        has_modeline = False
        for line in lines:
            # print(f"fuhua - check {line}")
            # 捕获 Modeline/ModeLine 行（兼容大小写和空格）
            if re.match(r'^\s*(Modeline|ModeLine)\s+"', line, re.I):
                has_modeline = True
                # 提取模式参数
                mode_match = re.search(r'"([^"]+)"', line)
                if not mode_match:
                    other_lines.append(line)
                    continue
                mode = mode_match.group(1)
                
                # 解析宽、高、刷新率（精确到小数点）
                try:
                    width_part, rest = mode.split('x', 1)
                    width = int(width_part)
                    height_part, refresh_part = rest.split('_', 1)
                    height = int(height_part)
                    refresh = float(refresh_part.split('.', 1)[0])  # 取整数部分
                except (ValueError, IndexError) as e:
                    # print(f"DEBUG: 解析失败 [{line}]", file=sys.stderr)
                    other_lines.append(line)
                    continue
                
                # 生成三级降序排序键（宽度→高度→刷新率）
                entries.append((-width, -height, -refresh, line))
            else:
                other_lines.append(line)
        
        # # 打印排序前的 entries
        # print("\n[DEBUG] === 排序前 entries ===", file=sys.stderr)
        # for entry in entries:
        #     print(f"  {entry[0]} -> {entry[1]}", file=sys.stderr)
        
        # 执行排序
        entries.sort()
        
        # # 打印排序后的 entries
        # print("\n[DEBUG] === 排序后 entries ===", file=sys.stderr)
        # for entry in entries:
        #     print(f"  {entry[0]} -> {entry[1]}", file=sys.stderr)
        
        # 合并结果：保留注释，插入排序后的时序
        processed.extend(other_lines)
        for entry in entries:
            processed.append(entry[3])

    # 如果没有 Modeline，添加默认时序
    if not has_modeline:
        processed.append("    # no edid get, we set default modeline")
        default_modelines = [
            'Modeline "1920x1080_60.00" 148.5 1920 2008 2052 2200 1080 1084 1089 1125 +HSync +VSync',
            # 'Modeline "1920x1080_60.00" 74.25 1920 2008 2052 2200 1080 1082 1087 1125 +HSync +VSync',
            'Modeline "1920x1080_30.00" 74.25 1920 2008 2052 2200 1080 1084 1089 1125 +HSync +VSync',
            'Modeline "1280x720_60.00" 74.25 1280 1390 1430 1650 720 725 730 750 +HSync +VSync',
            # 'Modeline "1280x720_50.00" 74.25 1280 1720 1760 1980 720 725 730 750 +HSync +VSync'
            'Modeline "1280x720_30.00" 74.25 1280 3040 3080 3300 720 725 730 750 +HSync +VSync'

        ]
        processed.extend(default_modelines)

    # print("################ end parse_and_sort ################")
    # 输出最终结果
    processed = [f"\t{line}" for line in processed]  # 所有行统一缩进
    print('\n'.join(processed))

if __name__ == '__main__':
    # print("######## start process_hobot_output.py ###########")
    parse_and_sort()
    # print("######## end process_hobot_output.py ###########")