Fair point. Let me start from absolute zero.

You have:

```text
10.15.30.42/24
```

The `/24` means:

> Out of the 32 bits in an IPv4 address, 24 belong to the network and 8 belong to the host.

But let's avoid bits for now.

---

## The trick

An IPv4 address has 4 numbers:

```text
10 . 15 . 30 . 42
 ^    ^    ^    ^
1st  2nd  3rd  4th octet
```

Every octet can contribute **up to 8 network bits**.

So:

```text
/24 = 8 + 8 + 8
```

That means:

* First octet fully used → 255
* Second octet fully used → 255
* Third octet fully used → 255
* Fourth octet not used → 0

Result:

```text
255.255.255.0
```

---

## Why does 8 become 255?

Because:

```text
8 bits used in an octet
```

means the octet is completely occupied by the network.

A completely occupied octet is always:

```text
255
```

So memorize:

```text
8 bits used = 255
0 bits used = 0
```

---

## Now let's do /20

```text
/20
```

Break it into groups of 8:

```text
20 = 8 + 8 + 4
```

First 8 → 255

Second 8 → 255

Remaining 4 bits go into the third octet.

So we have:

```text
255.255.?.0
```

Now the question becomes:

> What number represents 4 bits used in an octet?

That's where the table comes from.

| Bits used in octet | Value |
| ------------------ | ----- |
| 0                  | 0     |
| 1                  | 128   |
| 2                  | 192   |
| 3                  | 224   |
| 4                  | 240   |
| 5                  | 248   |
| 6                  | 252   |
| 7                  | 254   |
| 8                  | 255   |

Since we have **4 bits remaining**:

```text
4 -> 240
```

Therefore:

```text
255.255.240.0
```

---

## Your real question

> Where did this weird table come from?

Unfortunately, that table **comes from binary**.

For example:

```text
4 bits used

11110000
```

Convert that to decimal:

```text
128 + 64 + 32 + 16
= 240
```

That's why:

```text
4 -> 240
```

Similarly:

```text
11100000
= 128 + 64 + 32
= 224
```

So:

```text
3 -> 224
```

---

## What I would do if learning today

Don't memorize the whole table immediately.

Memorize only these powers of 2:

```text
128 64 32 16 8 4 2 1
```

Then if someone says:

```text
/20
```

You think:

```text
20 = 8 + 8 + 4
```

So:

```text
255.255.(128+64+32+16).0
```

which is:

```text
255.255.240.0
```

After doing this a few times, you'll stop calculating and just recognize:

```text
4 -> 240
```

instantly.

That's actually how most experienced engineers learned it—they understood it once, then eventually memorized the common masks through repetition.
Let's do it slowly, the way you might do it in an interview.

## Given

```text
192.168.50.100/26
```

---

## Step 1: Find the subnet mask

Take `/26`.

Break it into groups of 8:

```text
26 = 8 + 8 + 8 + 2
```

So:

* First octet = 255
* Second octet = 255
* Third octet = 255
* Fourth octet has 2 bits

From the table:

```text
2 bits → 192
```

Therefore:

```text
Subnet Mask = 255.255.255.192
```

---

## Step 2: Find the block size

Look at the interesting octet (the one with 192).

```text
256 - 192 = 64
```

Block size = **64**

The subnets will be:

```text
192.168.50.0
192.168.50.64
192.168.50.128
192.168.50.192
```

---

## Step 3: Find where 100 belongs

Your IP is:

```text
192.168.50.100
           ^^^
```

100 falls between:

```text
64 and 127
```

So the subnet starts at:

```text
192.168.50.64
```

✅ Network Address

---

## Step 4: Find Broadcast Address

Next subnet starts at:

```text
192.168.50.128
```

One less than that is:

```text
192.168.50.127
```

✅ Broadcast Address

---

## Step 5: Find Usable Range

First usable:

```text
192.168.50.65
```

Last usable:

```text
192.168.50.126
```

✅ Usable Host Range

---

## Step 6: Number of Hosts

```text
32 - 26 = 6 host bits
```

Total addresses:

```text
2^6 = 64
```

Usable:

```text
64 - 2 = 62
```

✅ 62 usable hosts

---

### Final Answer

```text
IP Address:       192.168.50.100/26
Subnet Mask:      255.255.255.192

Network Address:  192.168.50.64
Broadcast:        192.168.50.127

Usable Range:     192.168.50.65 - 192.168.50.126

Usable Hosts:     62
```

### Interview shortcut

For `/26`:

1. Mask = `255.255.255.192`
2. Block size = `256 - 192 = 64`
3. Subnets are `0, 64, 128, 192`
4. `100` falls in `64–127`
5. Network = `.64`
6. Broadcast = `.127`

You can do that in under 15 seconds once you've practiced a few times.
