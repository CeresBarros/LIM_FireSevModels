-- Bold table header cells (Word output)
function Table(tbl)
  for _, row in ipairs(tbl.head.rows) do
    for _, cell in ipairs(row.cells) do
      cell.contents = cell.contents:walk({
        Plain = function(el) return pandoc.Plain({pandoc.Strong(el.content)}) end,
        Para = function(el) return pandoc.Para({pandoc.Strong(el.content)}) end
      })
    end
  end
  return tbl
end
