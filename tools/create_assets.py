from pathlib import Path
import math, random, struct, wave
ROOT = Path(__file__).resolve().parent.parent
ART=ROOT/'assets/art'; AUDIO=ROOT/'assets/audio'
ART.mkdir(parents=True,exist_ok=True); AUDIO.mkdir(parents=True,exist_ok=True)
def sprite(name, rows, colors):
    pieces=['<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32" shape-rendering="crispEdges">']
    for y,row in enumerate(rows):
        for x,c in enumerate(row):
            if c in colors: pieces.append(f'<rect x="{x*2}" y="{y*2}" width="2" height="2" fill="{colors[c]}"/>')
    pieces.append('</svg>'); (ART/f'{name}.svg').write_text(''.join(pieces),encoding='utf8')
sprite('hunter', ['................','.....aaaaaa.....','....abbbbbba....','....abbbbbba....','.....ccccc......','....cdddddce....','....cddfd.ce....','.....dddd.ee....','....gggggg.e....','...hggggggh.....','...hgiijggh.....','....giijgg......','.....kkkk.......','....kk..kk......','....ll..ll......','................'],dict(a='#202e30',b='#b79961',c='#3d2c26',d='#e7bc87',e='#dfe4c4',f='#202b2a',g='#547c61',h='#283f3e',i='#c69a50',j='#eee0b3',k='#303b40',l='#b68654'))
creatures={ 'stalker':('#8fc586','#254947'), 'archer':('#d5b16d','#6a4541'), 'brute':('#b08088','#503957'), 'weaver':('#b7a4dd','#574b7a'), 'nest':('#cf9968','#5a5841'), 'boss':('#eac782','#934844') }
for name,(a,b) in creatures.items():
    rows=['................','....aaaaaaaa....','...abbbbbbbba...','..abbbbbbbbbba..','..abccbbbcc bba..'.replace(' ',''),'..abddbbbddbba..','...abbbbbbbba...','....aaaaaa......','...abbbbbba.....','..abbbbbbbba....','..abbbbbbbba....','...abbbbbba.....','...aaa..aaa.....','..aaa....aaa....','..bbb....bbb....','................']
    if name=='weaver': rows=['................','................','..a..........a..','...a..aaaa..a...','....aabbbbaa....','..aaa bccbaa aa..'.replace(' ',''),'....abddbbba....','....abbbbbba....','...aaabbbbaaa...','..a...aaaa...a..','..a..........a..','................','................','................','................','................']
    if name=='nest': rows=['................','................','......aaa.......','.....abbba......','....abccbba.....','...abbbbb bba....'.replace(' ',''),'..abbbbbbbbba...','..abbbbbbbbba...','..abbbbbbbbba...','...abbbbbbbba...','....abbbbbba....','..aaabbbbbbaaa..','.abbbbbbbbbbbba.','.aaaaaaaaaaaaaa.','................','................']
    sprite(name,rows,dict(a=a,b=b,c='#18282d',d='#fcf2c3'))
sprite('chest',['................','................','................','...aaaaaaaaaa...','..abbbbbbbbbba..','..abbbbbbbbbba..','..acccccccccca..','..acccddddccca..','..acccdeedccca..','..acccddddccca..','..acccccccccca..','..aaaaaaaaaaaa..','................','................','................','................'],dict(a='#252f35',b='#c39355',c='#7b513e',d='#eddba0',e='#303d45'))
sprite('key',['................','................','.....aaaa.......','....abbbba......','....ab..ba......','....ab..ba......','....abbbba......','.....aaaa.......','......aa........','......aa........','......aaaa......','......aa........','......aaaa......','................','................','................'],dict(a='#f2d18a',b='#9d703e'))
sprite('relic',['................','................','......aa........','.....abba.......','....abccba......','...abccccba.....','...abccccba.....','....abccba......','.....abba.......','......aa........','................','................','................','................','................','................'],dict(a='#e4eec5',b='#839e69',c='#3b7a6c'))
sprite('icon',['................','....aaaaaaaa....','...abbbbbbbba...','..abccccccccba..','..abccccccccba..','..abcddddccba...','..abcdccdcbba...','..abcddddccba...','..abccccccccba..','..abccccccccba..','...abbbbbbbba...','....aaaaaaaa....','................','................','................','................'],dict(a='#17252e',b='#cea769',c='#406050',d='#f0dba3'))
for index, palette in enumerate([('#d5b07a','#765043'),('#acc483','#415d51'),('#c5b395','#706362'),('#a7d7dd','#4b768a'),('#f0ad6b','#974d3d'),('#d4abe5','#594568')],1):
    original=(ART/'boss.svg').read_text(encoding='utf8')
    original=original.replace('#eac782',palette[0]).replace('#934844',palette[1])
    (ART/f'boss_{index}.svg').write_text(original,encoding='utf8')
RATE=22050
def save(name,values):
    with wave.open(str(AUDIO/f'{name}.wav'),'wb') as f:
        f.setnchannels(1);f.setsampwidth(2);f.setframerate(RATE)
        f.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,v))*22000)) for v in values))
random.seed(27)
for name,freq,duration in [('shot',740,.09),('hit',120,.16),('loot',960,.23),('door',190,.3),('roll',360,.16),('boss',75,.7),('clear',660,.65),('death',110,.8),('click',510,.07)]:
    save(name,[(math.sin(2*math.pi*freq*(i/RATE)*(1-(i/RATE)/duration*.45))*.22+(random.random()-.5)*(.2 if name in ['shot','hit','boss'] else .02))*(1-i/(RATE*duration))**2 for i in range(int(RATE*duration))])
scales=[[146.83,174.61,220,261.63],[130.81,155.56,196,233.08],[110,130.81,164.81,196],[164.81,196,246.94,293.66],[123.47,146.83,185,220],[110,130.81,155.56,207.65]]
for n,notes in enumerate(scales):
    values=[]; length=16; beat=.5
    for i in range(RATE*length):
        t=i/RATE; step=int(t/beat); phase=t%beat
        note=notes[[0,2,1,3,2,1,0,1][step%8]]
        lead=(math.sin(2*math.pi*note*2*t)+.18*math.sin(2*math.pi*note*4*t))*.065*math.exp(-phase*7)
        pad=sum(math.sin(2*math.pi*f*t) for f in notes[:3])*.019
        kick=math.sin(2*math.pi*55*phase)*.11*math.exp(-phase*25) if step%2==0 else 0
        values.append((lead+pad+kick)*min(1,t*4,(length-t)*4))
    save(f'music_{n+1}',values)
print('Arte SVG original e 15 faixas/efeitos WAV criados.')
