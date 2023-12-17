list = list or {}

function list.create()
    local lenght = 0
    -- 类似stl的方式，头尾只是作为指针使用
    local first = {front = nil, next = nil, value = nil}
    local last = {front = nil, next = nil, value = nil}
    first.next = last
    last.front = first


    ---查找值
    ---@param value
    ---@return node
    local find = function(value)
        local ret = nil
        local nextNode = first
        while nextNode do
            nextNode = nextNode.next
            if nextNode.value == value then
                ret = nextNode
                break
            end
        end

        return ret
    end

    ---查找(根据下标查找)
    ---@param idx 下标
    ---@return node
    local findByIdx = function(idx)
        local i = 0
        local ret
        local nextNode = first
        while nextNode and i < lenght do
            i = i+1
            nextNode = nextNode.next
            if i == idx then
                ret = nextNode
                break
            end
        end

        return ret
    end

    ---在node前添加
    ---@param node
    ---@param v
    local addBefore = function(node, v)
        assert(node)

        local frontNode = node.front
        local newNode = {}
        newNode.front = frontNode
        newNode.next = node
        newNode.value = v
        node.front = newNode
        frontNode.next = newNode

        lenght = lenght+1
    end

    ---在node后添加
    ---@param node
    ---@param v
    local addAfter = function(node, v)
        assert(node)
        local nextNode = node.next
        local newNode = {}
        newNode.front = node
        newNode.next = nextNode
        newNode.value = v
        node.next = newNode
        nextNode.front = newNode

        lenght = lenght+1
    end

    ---在队首添加
    ---@param v
    local addFirst = function(v)
        addAfter(first, v)
    end

    ---在队尾添加
    ---@param v
    local addLast = function(v)
        addBefore(last, v)
    end

    ---删除节点
    ---@param node
    local removeNode = function(node)
        assert(node)

        local frontNode = node.front
        local nextNode = node.next

        if frontNode == nil then
            first = nextNode
        else
            frontNode.next = nextNode
        end

        if nextNode ~= nil then
            nextNode.front = frontNode
        end
        lenght = lenght - 1
    end

    ---删除节点
    ---@param v
    local remove = function(v)
        local node = find(v)
        if node then
            removeNode(node)
        end
    end

    local t = {
        addFirst = addFirst,
        addLast = addLast,
        addBefore = addBefore,
        addAfter = addAfter,
        removeNode = removeNode,
        remove = remove,
        find = find,
        findByIdx = findByIdx
    }

    local mt = {
        __index = function(i_t, key)
            return findByIdx(key)
        end,
        __newindex = function(i_t,k,v)
            local node = findByIdx(k)
            if not node then
                error("out range: "..k)
            else
                node.value = v
            end
        end,
        __tostring = function()
            local ret = {}
            local next = first.next
            while next and next ~= last do
                ret[#ret+1] = next.value
                next = next.next
            end

            return table.concat(ret, ',')
        end,
        __len = function(v)
            return lenght
        end,
        --迭代器返回node-value
        __ipairs = function(i_t)
            local idx = 0
            local function iter(i_t, node)
                idx = idx + 1
                if node and node.next ~= last then
                    return node.next, idx, node.next.value
                end
            end

            return iter, t, first
        end,
        __pairs = function(i_t)
            local function iter(i_t, node)
                if node and node.next ~= last then
                    return node.next, node.next.value
                end
            end

            return iter, t, first
        end
    }

    setmetatable(t, mt)

    return t
end

return list